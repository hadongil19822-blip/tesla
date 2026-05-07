import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});

  @override
  State<AssistanceScreen> createState() => _AssistanceScreenState();
}

class _AssistanceScreenState extends State<AssistanceScreen> {
  // 스위치 상태
  bool _speedAlertEnabled = false;
  bool _autoFrunkEnabled = true;
  double _speedLimitOffset = 10; // +10km/h 오차 허용

  // 주행 속도 시뮬레이션 관련
  double _currentSimulatedSpeed = 0.0;
  double _targetSpeedLimit = 60.0; // 현재 도로 제한 속도 60km/h라고 가정
  
  // TTS & 경고 시스템
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _warningTimer;
  bool _isWarningPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _checkSpeedAndWarn() {
    if (!_speedAlertEnabled) {
      _stopWarning();
      return;
    }

    // 허용 속도 초과 시 작동
    double allowedSpeed = _targetSpeedLimit + _speedLimitOffset;
    if (_currentSimulatedSpeed > allowedSpeed) {
      _startWarning();
    } else {
      _stopWarning();
    }
  }

  void _startWarning() {
    if (_warningTimer != null && _warningTimer!.isActive) return; // 이미 울리고 있음
    
    // 계속해서 경고 반복 (이전 스레드에서 원하셨던 '지속적인' 알림 기능)
    // 2초마다 경고음(TTS) 발생
    _warningTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || !_speedAlertEnabled) {
        timer.cancel();
        return;
      }
      setState(() => _isWarningPlaying = true);
      await _flutterTts.speak("과속입니다. 속도를 줄여주세요.");
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _isWarningPlaying = false);
      });
    });
  }

  void _stopWarning() {
    _warningTimer?.cancel();
    _warningTimer = null;
    _flutterTts.stop();
    if (mounted && _isWarningPlaying) {
      setState(() => _isWarningPlaying = false);
    }
  }

  @override
  void dispose() {
    _stopWarning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보조 및 자동화 (Routine)'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주행 보조 (Driving Assist)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // 1. 과속 연속 경고음 기능 (사용자 요청 기능)
              _buildSwitchCard(
                icon: CupertinoIcons.speedometer,
                title: '과속 연속 경고 알림 기능',
                subtitle: '제한 속도 초과 시 계속 경고를 줍니다. (TTS 구동)',
                value: _speedAlertEnabled,
                isWarningActive: _isWarningPlaying,
                onChanged: (val) {
                  setState(() {
                    _speedAlertEnabled = val;
                    _checkSpeedAndWarn();
                  });
                },
              ),
              if (_speedAlertEnabled) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('허용 오차: ', style: TextStyle(color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: _speedLimitOffset,
                          min: 0,
                          max: 30,
                          divisions: 6,
                          label: '+${_speedLimitOffset.toInt()} km/h',
                          onChanged: (val) {
                            setState(() {
                              _speedLimitOffset = val;
                              _checkSpeedAndWarn();
                            });
                          },
                        ),
                      ),
                      Text('+${_speedLimitOffset.toInt()} km/h',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 시뮬레이터 UI (개발 및 테스트용)
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🧪 주행 속도 테스트 시뮬레이터', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          Text('기준 속도: 60 km/h', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('현재 속도:', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${_currentSimulatedSpeed.toInt()} km/h',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isWarningPlaying ? Colors.redAccent : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _currentSimulatedSpeed,
                        min: 0,
                        max: 150,
                        activeColor: _isWarningPlaying ? Colors.redAccent : Colors.blueAccent,
                        onChanged: (val) {
                          setState(() {
                            _currentSimulatedSpeed = val;
                            _checkSpeedAndWarn();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 48),

              const Text(
                '자동화 루틴 (Routine)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 2. 집 접근 시 프렁크 오픈
              _buildSwitchCard(
                icon: CupertinoIcons.home,
                title: '도착 전 프렁크 자동 오픈',
                subtitle: '집 반경 50m 진입 시 프렁크를 자동으로 엽니다.',
                value: _autoFrunkEnabled,
                onChanged: (val) {
                  setState(() => _autoFrunkEnabled = val);
                },
              ),

              const SizedBox(height: 16),
              
              // 3. 겨울철 예열 루틴 (시각적 표시만)
              _buildActionCard(
                icon: CupertinoIcons.snow,
                title: '겨울철 출근길 예열 추가',
                subtitle: '조건을 만족하면 아침에 히터를 켭니다.',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('설정 화면으로 이동합니다.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isWarningActive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarningActive 
            ? Colors.redAccent.withOpacity(0.2) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarningActive ? Colors.redAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: isWarningActive ? Colors.redAccent : (value ? Colors.blueAccent : Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: isWarningActive ? Colors.redAccent : Colors.blueAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
