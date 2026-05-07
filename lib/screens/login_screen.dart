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
  final _tokenController = TextEditingController();
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
      _tokenController.text = token;
      // 자동 로그인 시도
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

  void _handleTokenLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('토큰 값을 입력해주세요!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = TeslaApiService();
    final isValid = await apiService.verifyToken(token);

    if (!mounted) return;

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tesla_token', token);

      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효하지 않은 토큰입니다.')),
      );
    }
  }

  Future<void> _handleOfficialLogin() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보안 정책 안내'),
        content: const Text('테슬라의 강력한 보안 정책(CORS 및 방화벽)으로 인해, 백엔드 서버가 없는 순수 웹페이지(GitHub Pages)에서는 공식 로그인을 마칠 수 없습니다.\n\n앱스토어에서 "Auth app for Tesla" 등의 앱을 이용해 토큰을 발급받아 아래 입력창에 직접 붙여넣어 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
                const Icon(CupertinoIcons.car_detailed, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'My Smart Car Web',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '테슬라 공식 웹 로그인은 백엔드 서버가 필요합니다.\n임시로 토큰 직접 입력 방식을 사용하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                // 공식 로그인 버튼 (안내 팝업용)
                ElevatedButton(
                  onPressed: _handleOfficialLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE82127), // 테슬라 레드
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tesla 계정으로 로그인 (안내)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('또는', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                ),
                
                // 토큰 입력
                TextField(
                  controller: _tokenController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ey... 로 시작하는 Access Token 입력',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 토큰 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleTokenLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('토큰으로 차량 연결하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                
                // 건너뛰기 버튼
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}

