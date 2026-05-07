import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'navigation_screen.dart';
import 'entertainment_screen.dart';
import 'analytics_screen.dart';
import 'assistance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NavigationScreen(),
    const EntertainmentScreen(),
    const AnalyticsScreen(),
    const AssistanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.car_detailed),
            label: '제어',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation_rounded),
            label: '내비',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline_rounded),
            label: '엔터',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.shield_fill),
            label: '보조',
          ),
        ],
      ),
    );
  }
}
