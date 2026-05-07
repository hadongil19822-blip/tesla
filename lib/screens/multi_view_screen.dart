import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/tesla_api_service.dart';

class MultiViewScreen extends StatefulWidget {
  const MultiViewScreen({super.key});

  @override
  State<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends State<MultiViewScreen> {
  final TeslaApiService _apiService = TeslaApiService();
  final TextEditingController _destController = TextEditingController();
  
  static const _workerUrl = 'https://tesla-auth-proxy.hadongil19822.workers.dev';
  
  // 차량 상태
  int _batteryLevel = 0;
  bool _isLocked = true;
  bool _isClimateOn = false;
  double _insideTemp = 0;
  
  // 세션
  String _sessionId = 'default';
  bool _isSending = false;
  String _lastSentDest = '';
  
  // 뷰 상태
  bool _showMap = true;
  bool _showYoutube = false;
  bool _isHorizontalSplit = false;
  double _splitRatio = 0.55;

  // iframe
  String? _mapViewType;
  int _mapViewId = 0;
  String? _ytViewType;
  int _ytViewId = 0;
  bool _ytReady = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleStatus();
    _registerMap();
  }

  void _registerMap([String? destination]) {
    // 네이티브 환경에서는 webview_flutter 등을 사용해야 합니다.
    // 현재는 미러링 기능에 집중하기 위해 웹 전용 코드를 제거합니다.
    setState(() {
      _mapViewType = null;
    });
  }

  void _openYoutube() {
    setState(() {
      _ytViewType = null;
    });
  }

  Future<void> _loadVehicleStatus() async {
    try {
      final data = await _apiService.fetchVehicleData();
      if (mounted) {
        setState(() {
          final cs = data['charge_state'] ?? {};
          _batteryLevel = cs['battery_level'] ?? 0;
          final vs = data['vehicle_state'] ?? {};
          _isLocked = vs['locked'] ?? true;
          final cl = data['climate_state'] ?? {};
          _isClimateOn = cl['is_climate_on'] ?? false;
          _insideTemp = (cl['inside_temp'] ?? 0).toDouble();
        });
      }
    } catch (_) {}
  }

  /// 📱→🚗 목적지를 테슬라 화면으로 전송
  Future<void> _sendToTesla(String destination) async {
    if (destination.trim().isEmpty) return;
    setState(() => _isSending = true);
    
    try {
      await http.post(
        Uri.parse('$_workerUrl/screen/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'destination': destination.trim(),
        }),
      );
      setState(() => _lastSentDest = destination.trim());
      
      // 폰의 지도도 같은 목적지로 업데이트
      _registerMap(destination.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 "$destination" → 테슬라 화면으로 전송 완료!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showTeslaConnectDialog() {
    final displayUrl = '$_workerUrl/display?session=$_sessionId';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.screen_share_rounded, size: 48, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text('테슬라 화면 연결', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              '테슬라 차량의 브라우저에서\n아래 주소를 입력하세요:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  SelectableText(
                    displayUrl,
                    style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: displayUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL이 복사되었습니다!'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('URL 복사'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '연결 후 이 화면에서 목적지를 입력하면\n테슬라 화면에 자동으로 표시됩니다! 🚗',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            _buildDestinationBar(),
            _buildToolbar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Icon(
            _batteryLevel > 20 ? CupertinoIcons.battery_75_percent : CupertinoIcons.battery_25_percent,
            color: _batteryLevel > 20 ? Colors.green : Colors.red, size: 16,
          ),
          const SizedBox(width: 3),
          Text('$_batteryLevel%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Icon(_isLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill,
            color: _isLocked ? Colors.grey : Colors.blueAccent, size: 14),
          const SizedBox(width: 10),
          const Icon(CupertinoIcons.thermometer, size: 14, color: Colors.orangeAccent),
          Text(' ${_insideTemp.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Spacer(),
          // 테슬라 연결 버튼
          GestureDetector(
            onTap: _showTeslaConnectDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.withValues(alpha: 0.3), Colors.purpleAccent.withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.screen_share_rounded, size: 14, color: Colors.blueAccent),
                  SizedBox(width: 4),
                  Text('테슬라 연결', style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _loadVehicleStatus,
            child: const Icon(CupertinoIcons.refresh, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _destController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '목적지 검색 (예: 강남역, 제주공항)',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (v) => _sendToTesla(v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 테슬라로 보내기 버튼
          GestureDetector(
            onTap: _isSending ? null : () => _sendToTesla(_destController.text),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE82127), Color(0xFFFF4444)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('전송', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _buildToggle('지도', Icons.map_rounded, _showMap, () {
            setState(() => _showMap = !_showMap);
          }),
          const SizedBox(width: 6),
          _buildToggle('YouTube', Icons.play_circle_rounded, _showYoutube, () {
            setState(() => _showYoutube = !_showYoutube);
            if (_showYoutube && !_ytReady) _openYoutube();
          }),
          if (_showMap && _showYoutube) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _isHorizontalSplit = !_isHorizontalSplit),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isHorizontalSplit ? Icons.view_column_rounded : Icons.view_agenda_rounded,
                      size: 14, color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 3),
                    Text(_isHorizontalSplit ? '좌우' : '상하',
                      style: const TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_lastSentDest.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('$_lastSentDest', 
                    style: const TextStyle(fontSize: 10, color: Colors.green),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.blueAccent : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.blueAccent : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_showMap && !_showYoutube) {
      return const Center(child: Text('지도 또는 YouTube를 켜주세요', style: TextStyle(color: Colors.grey)));
    }
    if (!_showMap) return _buildYoutubePanel();
    if (!_showYoutube) return _buildMapPanel();

    // 분할 뷰
    if (_isHorizontalSplit) {
      return Row(
        children: [
          Expanded(flex: (_splitRatio * 100).toInt(), child: _buildMapPanel()),
          _buildDivider(true),
          Expanded(flex: ((1 - _splitRatio) * 100).toInt(), child: _buildYoutubePanel()),
        ],
      );
    }
    return Column(
      children: [
        Expanded(flex: (_splitRatio * 100).toInt(), child: _buildMapPanel()),
        _buildDivider(false),
        Expanded(flex: ((1 - _splitRatio) * 100).toInt(), child: _buildYoutubePanel()),
      ],
    );
  }

  Widget _buildDivider(bool horizontal) {
    return GestureDetector(
      onVerticalDragUpdate: horizontal ? null : (d) {
        setState(() {
          _splitRatio = (_splitRatio + d.delta.dy / MediaQuery.of(context).size.height).clamp(0.2, 0.8);
        });
      },
      onHorizontalDragUpdate: horizontal ? (d) {
        setState(() {
          _splitRatio = (_splitRatio + d.delta.dx / MediaQuery.of(context).size.width).clamp(0.2, 0.8);
        });
      } : null,
      child: Container(
        width: horizontal ? 10 : double.infinity,
        height: horizontal ? double.infinity : 10,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: horizontal ? 4 : 40,
            height: horizontal ? 40 : 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _mapViewType != null
          ? HtmlElementView(viewType: _mapViewType!)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildYoutubePanel() {
    if (_ytReady && _ytViewType != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: _ytViewType!),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF0000), size: 48),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _openYoutube,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('YouTube 열기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
