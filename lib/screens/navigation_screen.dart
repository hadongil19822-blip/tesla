import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  // 선택된 네비게이션 앱
  String _selectedNavApp = 'TMAP';
  final List<Map<String, dynamic>> _navApps = [
    {
      'name': 'TMAP',
      'icon': Icons.navigation_rounded,
      'color': Color(0xFF4A6CF7),
      'package': 'com.skt.tmap.ku',
      'scheme': 'tmap://',
    },
    {
      'name': 'NAVER Map',
      'icon': Icons.map_rounded,
      'color': Color(0xFF1EC800),
      'package': 'com.nhn.android.nmap',
      'scheme': 'nmap://',
    },
    {
      'name': 'KakaoNavi',
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFFFEE500),
      'package': 'com.locnall.KimGiSa',
      'scheme': 'kakaonavi://',
    },
  ];

  // 자동화 토글 상태
  bool _autoNavStart = true;
  bool _autoAirplaneMode = false;
  bool _autoMusicResume = true;


  // 화면 캐스팅 상태
  bool _isCasting = false;
  bool _isConnecting = false;

  // 연결 상태
  String _connectionStatus = '미연결';
  String _castingQuality = '1080p';

  // 애니메이션
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _castGlowController;
  late Animation<double> _castGlowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _castGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _castGlowAnimation = Tween(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _castGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _castGlowController.dispose();
    super.dispose();
  }

  void _startCasting() async {
    setState(() => _isConnecting = true);
    // 연결 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isCasting = true;
        _connectionStatus = '차량 디스플레이 연결됨';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cast_connected, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$_selectedNavApp → 차량 디스플레이에 캐스팅 시작 📱➡️🚗'),
            ],
          ),
          backgroundColor: const Color(0xFF4A6CF7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _stopCasting() {
    setState(() {
      _isCasting = false;
      _connectionStatus = '미연결';
    });
  }

  void _launchNavApp() async {
    final app = _navApps.firstWhere((a) => a['name'] == _selectedNavApp);
    final scheme = app['scheme'] as String;
    final uri = Uri.parse(scheme);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_selectedNavApp 앱이 설치되어 있지 않습니다.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedNavApp 실행에 실패했습니다.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내비게이션 & 캐스팅'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 연결 상태 카드
              _buildConnectionStatusCard(),
              const SizedBox(height: 24),

              // 2. 네비 앱 선택
              const Text(
                '네비게이션 앱 선택',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildNavAppSelector(),
              const SizedBox(height: 24),

              // 3. 캐스팅 컨트롤
              _buildCastingControl(),
              const SizedBox(height: 28),

              // 4. 자동화 설정 (Tesor 스타일)
              const Text(
                '자동화 설정',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAutomationCard(
                icon: Icons.navigation_rounded,
                iconColor: const Color(0xFF4A6CF7),
                title: '안전운행 자동 시작',
                subtitle: '연결 시 안전운행 모드를 자동으로 실행합니다',
                value: _autoNavStart,
                trailing: _buildNavAppDropdown(),
                onChanged: (v) => setState(() => _autoNavStart = v),
              ),
              const SizedBox(height: 10),
              _buildAutomationCard(
                icon: Icons.airplanemode_active_rounded,
                iconColor: Colors.purpleAccent,
                title: '비행기 모드 자동 설정',
                subtitle: 'Tesor 상태에 따라 자동으로 비행기 모드를 켜고 끕니다',
                value: _autoAirplaneMode,
                onChanged: (v) => setState(() => _autoAirplaneMode = v),
              ),
              const SizedBox(height: 10),
              _buildAutomationCard(
                icon: Icons.play_circle_fill_rounded,
                iconColor: Colors.orangeAccent,
                title: '음악 자동 재생',
                subtitle: '연결 시 음악이 자동으로 재개됩니다',
                value: _autoMusicResume,
                onChanged: (v) => setState(() => _autoMusicResume = v),
              ),
              const SizedBox(height: 28),

              // 5. 캐스팅 품질 설정
              const Text(
                '캐스팅 설정',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildQualitySelector(),
              const SizedBox(height: 16),

              // 6. 도움말
              _buildInfoCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    final isConnected = _isCasting;
    return AnimatedBuilder(
      animation: _castGlowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected
                  ? [const Color(0xFF1A3A5C), const Color(0xFF0D2137)]
                  : [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF4A6CF7).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7).withValues(alpha: 0.15),
                      blurRadius: _castGlowAnimation.value * 2,
                      spreadRadius: _castGlowAnimation.value / 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF4A6CF7).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Icon(
                      isConnected ? Icons.cast_connected : Icons.cast_rounded,
                      color: isConnected
                          ? Color.lerp(
                              const Color(0xFF4A6CF7),
                              Colors.white,
                              _pulseAnimation.value - 0.6,
                            )
                          : Colors.grey,
                      size: 28,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? '$_selectedNavApp 캐스팅 중 • $_castingQuality'
                          : '차량 Wi-Fi 핫스팟에 연결해주세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: isConnected
                            ? const Color(0xFF4A6CF7)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 상태 인디케이터
              if (isConnected)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavAppSelector() {
    return Row(
      children: _navApps.map((app) {
        final isSelected = _selectedNavApp == app['name'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedNavApp = app['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (app['color'] as Color).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (app['color'] as Color).withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    app['icon'] as IconData,
                    color: isSelected ? app['color'] as Color : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCastingControl() {
    return Column(
      children: [
        // 메인 캐스팅 버튼
        GestureDetector(
          onTap: () {
            if (_isConnecting) return;
            if (_isCasting) {
              _stopCasting();
            } else {
              _startCasting();
            }
          },
          child: AnimatedBuilder(
            animation: _castGlowAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: _isCasting
                      ? const LinearGradient(
                          colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF4A6CF7), Color(0xFF6C8DFF)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCasting
                              ? const Color(0xFFFF4757)
                              : const Color(0xFF4A6CF7))
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isConnecting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        _isCasting ? Icons.stop_rounded : Icons.cast_rounded,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _isConnecting
                          ? '연결 중...'
                          : _isCasting
                              ? '캐스팅 중지'
                              : '📱 $_selectedNavApp 캐스팅 시작',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 네비앱 직접 실행 버튼
        GestureDetector(
          onTap: _launchNavApp,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.open_in_new_rounded,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$_selectedNavApp 앱 직접 실행',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavAppDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNavApp,
          dropdownColor: const Color(0xFF2C2C2E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
          isDense: true,
          items: _navApps
              .map((app) => DropdownMenuItem(
                    value: app['name'] as String,
                    child: Text(app['name'] as String),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedNavApp = v);
          },
        ),
      ),
    );
  }

  Widget _buildAutomationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: iconColor,
                onChanged: onChanged,
              ),
            ],
          ),
          if (trailing != null && value) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [trailing],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    final qualities = ['720p', '1080p', '1440p'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.high_quality_rounded, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text('캐스팅 화질', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: qualities.map((q) {
              final isSelected = _castingQuality == q;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _castingQuality = q),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A6CF7).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4A6CF7)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      q,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A6CF7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A6CF7).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4A6CF7), size: 20),
              SizedBox(width: 8),
              Text(
                '사용 가이드',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF4A6CF7)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('1', '폰의 모바일 핫스팟을 5GHz로 설정합니다'),
          _buildInfoRow('2', '차량 브라우저에서 Tesor 연결 주소에 접속합니다'),
          _buildInfoRow('3', '이 앱에서 캐스팅 시작 버튼을 누릅니다'),
          _buildInfoRow('4', '내비게이션이 차량 화면에 표시됩니다'),
          const SizedBox(height: 8),
          Text(
            '※ 로컬 네트워크를 사용하므로 모바일 데이터가 소모되지 않습니다',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6CF7))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }
}
