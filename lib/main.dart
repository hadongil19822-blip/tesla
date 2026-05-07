import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TeslaSuperApp());
}

class TeslaSuperApp extends StatelessWidget {
  const TeslaSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tesla Super App',
      themeMode: ThemeMode.dark, // 테슬라 특유의 다크포스!
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.blueAccent,
          surface: Color(0xFF2C2C2E),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
