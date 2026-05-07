import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncherScreen extends StatelessWidget {
  const AppLauncherScreen({super.key});

  // 앱 목록 (누르면 설치된 앱이 바로 실행됨)
  static final List<Map<String, dynamic>> _apps = [
    {
      'name': 'YouTube',
      'icon': Icons.play_circle_fill_rounded,
      'color': const Color(0xFFFF0000),
      'url': 'https://www.youtube.com',
    },
    {
      'name': 'Netflix',
      'icon': Icons.movie_filter_rounded,
      'color': const Color(0xFFE50914),
      'url': 'https://www.netflix.com',
    },
    {
      'name': 'T map',
      'icon': Icons.navigation_rounded,
      'color': const Color(0xFF2196F3),
      'url': 'https://www.tmap.co.kr',
    },
    {
      'name': 'Disney+',
      'icon': Icons.castle_rounded,
      'color': const Color(0xFF113CCF),
      'url': 'https://www.disneyplus.com',
    },
    {
      'name': 'Wavve',
      'icon': Icons.waves_rounded,
      'color': const Color(0xFF1D1D6D),
      'url': 'https://www.wavve.com',
    },
    {
      'name': 'Tving',
      'icon': Icons.tv_rounded,
      'color': const Color(0xFFFF153C),
      'url': 'https://www.tving.com',
    },
    {
      'name': 'Coupang Play',
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFFE3004F),
      'url': 'https://www.coupangplay.com',
    },
    {
      'name': 'Spotify',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFF1DB954),
      'url': 'https://open.spotify.com',
    },
    {
      'name': '카카오내비',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFFFEE500),
      'url': 'https://kakaonavi.kakao.com',
    },
    {
      'name': '네이버 지도',
      'icon': Icons.map_rounded,
      'color': const Color(0xFF03C75A),
      'url': 'https://map.naver.com',
    },
    {
      'name': '멜론',
      'icon': Icons.headphones_rounded,
      'color': const Color(0xFF00CD3C),
      'url': 'https://www.melon.com',
    },
    {
      'name': '슈퍼차저',
      'icon': Icons.ev_station_rounded,
      'color': const Color(0xFFE82127),
      'url': 'https://www.tesla.com/findus?v=2&bounds=37.5665,126.9780',
    },
  ];

  Future<void> _launchApp(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 실행'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: _apps.length,
          itemBuilder: (context, index) {
            final app = _apps[index];
            final color = app['color'] as Color;
            return GestureDetector(
              onTap: () => _launchApp(app['url'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(app['icon'] as IconData, color: color, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      app['name'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
