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

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  void _checkExistingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tesla_token');
    if (token != null && token.isNotEmpty) {
      // Auto login if token exists
      final apiService = TeslaApiService();
      apiService.setToken(token);
      final isValid = await apiService.verifyToken(token);
      if (isValid && mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _handleOfficialLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientId = '0c603db8-e784-4ff4-9170-f07d4f1e2d55';
      final clientSecret = 'ta-secret.r2k7Ntla@h*FLIn!';
      final redirectUri = 'https://hadongil19822-blip.github.io/tesla/auth.html';
      
      final url = Uri.https('auth.tesla.com', '/oauth2/v3/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'openid vehicle_device_data vehicle_cmds offline_access',
        'state': '12345'
      });

      // 1. 공식 테슬라 웹 로그인 창 띄우기
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'https',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('인증 코드를 받지 못했습니다.');

      // 2. 코드를 토큰으로 교환하기
      final tokenUrl = 'https://corsproxy.io/?${Uri.encodeComponent('https://auth.tesla.com/oauth2/v3/token')}';
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
          'audience': 'https://fleet-api.prd.na.vn.cloud.tesla.com'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tesla_token', accessToken);

        final apiService = TeslaApiService();
        final isValid = await apiService.verifyToken(accessToken);

        if (isValid && mounted) {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          throw Exception('차량 정보를 불러올 수 없습니다.');
        }
      } else {
        throw Exception('토큰 발급 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                    backgroundColor: const Color(0xFFE82127), // 테슬라 레드
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Tesla 계정으로 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                
                // 건너뛰기 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(builder: (context) => const MainScreen()),
                        );
                      },
                      child: const Text('토큰 없이 둘러보기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
