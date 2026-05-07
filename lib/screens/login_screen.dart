import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'main_screen.dart';
import '../services/tesla_api_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

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
    // 웹에서 리다이렉트로 돌아왔을 때 코드 확인
    if (kIsWeb) {
      _checkRedirectCode();
    } else {
      _checkExistingToken();
    }
  }

  /// URL에 ?code= 파라미터가 있으면 토큰 교환 진행
  void _checkRedirectCode() async {
    try {
      final uri = Uri.base;
      final code = uri.queryParameters['code'];
      
      if (code != null && code.isNotEmpty) {
        // URL 정리 (코드 파라미터 제거)
        _cleanUrl();
        
        setState(() {
          _isLoading = true;
          _statusMessage = '토큰 발급 중...';
        });

        // Cloudflare Worker를 통해 토큰 교환
        final tokenResponse = await http.post(
          Uri.parse('$_workerUrl/token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code}),
        );

        if (tokenResponse.statusCode == 200) {
          final tokenData = jsonDecode(tokenResponse.body);
          final accessToken = tokenData['access_token'];
          
          if (accessToken != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('tesla_token', accessToken);
            if (tokenData['refresh_token'] != null) {
              await prefs.setString('tesla_refresh_token', tokenData['refresh_token']);
            }

            setState(() { _statusMessage = '차량 연결 중...'; });

            final apiService = TeslaApiService();
            apiService.setToken(accessToken);

            if (mounted) {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (context) => const MainScreen()),
              );
            }
            return;
          }
        }
        
        // 토큰 교환 실패
        final errBody = jsonDecode(tokenResponse.body);
        final errorMsg = errBody['error'] ?? '토큰 발급 실패';
        
        // 사파리 등에서 코드가 2번 사용된 경우
        if (errorMsg.toString().contains('invalid_grant')) {
          throw Exception('보안 코드가 만료되었습니다. 다시 로그인해주세요.');
        }
        throw Exception(errorMsg);
      } else {
        // 코드가 없으면 기존 토큰 확인
        _checkExistingToken();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        
        // 에러 시 즉시 URL을 정리하여 무한 루프 방지
        _cleanUrl();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), 
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanUrl() {
    // 웹 환경에서는 dart:html이 필요하므로 네이티브 앱에서는 사용하지 않음
  }

  void _checkExistingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tesla_token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _statusMessage = '자동 로그인 중...';
      });
      final apiService = TeslaApiService();
      apiService.setToken(token);
      // 토큰 검증 생략 → 차량이 수면 중이면 검증 실패하므로 바로 진입
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  void _handleOfficialLogin() async {
    final authUrl = Uri.https('auth.tesla.com', '/oauth2/v3/authorize', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'openid vehicle_device_data vehicle_cmds offline_access',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 페이지를 열 수 없습니다.')),
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
                            Flexible(
                              child: Text(
                                _statusMessage.isNotEmpty ? _statusMessage : '처리 중...',
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Text('Tesla 계정으로 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                
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
