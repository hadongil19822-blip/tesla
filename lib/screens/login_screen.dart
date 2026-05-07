import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

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

    // 토큰 저장 (다음 접속 시 편리하게)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tesla_token', token);

    // TODO: 이 토큰을 TeslaApiService로 넘겨주어 검증하는 로직 추가

    await Future.delayed(const Duration(seconds: 1)); // 시뮬레이션

    if (!mounted) return;

    // 메인 화면으로 이동
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (context) => const MainScreen()),
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
                const Icon(CupertinoIcons.car_detailed, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Tesla Super App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '비공식 토큰(Token) 방식으로 로그인합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 64),
                
                // 토큰 입력 (기존 이메일/비번 대신)
                TextField(
                  controller: _tokenController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '이곳에 eyJ... 로 시작하는 Refresh Token 또는 Access Token을 붙여넣으세요.',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleTokenLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('토큰으로 차량 연결하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                
                // 안내 링크
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Store에서 "Auth app for Tesla"를 검색해보세요!')),
                    );
                  },
                  child: const Text('토큰을 어디서 구하나요?', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
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
