import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'main_screen.dart';
import '../services/tesla_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  static const _clientId = '0c603db8-e784-4ff4-9170-f07d4f1e2d55';
  static const _redirectUri = 'https://hadongil19822-blip.github.io/tesla/auth.html';
  static const _workerUrl = 'https://tesla-auth-proxy.hadongil19822.workers.dev';

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  void _checkExistingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tesla_token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _statusMessage = '저장된 토큰으로 자동 로그인 중...';
      });
      final apiService = TeslaApiService();
      apiService.setToken(token);
      final isValid = await apiService.verifyToken(token);
      if (isValid && mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = '';
          });
        }
      }
    }
  }

  Future<void> _handleOfficialLogin() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '테슬라 로그인 페이지 여는 중...';
    });

    try {
      // 1단계: 테슬라 공식 로그인 창 띄우기
      final authUrl = Uri.https('auth.tesla.com', '/oauth2/v3/authorize', {
        'response_type': 'code',
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'scope': 'openid vehicle_device_data vehicle_cmds offline_access',
        'state': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'https',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('인증 코드를 받지 못했습니다.');

      setState(() {
        _statusMessage = '토큰 발급 중... (Cloudflare Worker 경유)';
      });

      // 2단계: Cloudflare Worker를 통해 인증코드 → 토큰 교환
      final tokenResponse = await http.post(
        Uri.parse('$_workerUrl/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (tokenResponse.statusCode != 200) {
        final errData = jsonDecode(tokenResponse.body);
        throw Exception('토큰 발급 실패: ${errData['error'] ?? tokenResponse.statusCode}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];
      if (accessToken == null) throw Exception('Access Token이 응답에 없습니다.');

      // 3단계: 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tesla_token', accessToken);
      if (tokenData['refresh_token'] != null) {
        await prefs.setString('tesla_refresh_token', tokenData['refresh_token']);
      }

      setState(() {
        _statusMessage = '차량 정보 불러오는 중...';
      });

      // 4단계: 차량 연결 확인 후 메인 화면 이동
      final apiService = TeslaApiService();
      final isValid = await apiService.verifyToken(accessToken);

      if (isValid && mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
        );
      } else if (mounted) {
        // 토큰은 발급됐지만 차량 조회 실패 (차량이 잠자는 중일 수 있음)
        // 그래도 토큰은 유효하므로 메인으로 이동
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(CupertinoIcons.car_detailed, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'My Smart Car Web',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '테슬라 공식 계정으로 안전하게 로그인하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 64),
                
                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleOfficialLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE82127),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Text(_statusMessage.isNotEmpty ? _statusMessage : '처리 중...', 
                              style: const TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        )
                      : const Text('Tesla 계정으로 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                
                // 건너뛰기 버튼
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  child: const Text('토큰 없이 둘러보기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
