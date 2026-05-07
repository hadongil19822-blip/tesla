import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _currentVideoId;
  bool _isPlayerVisible = false;
  int _viewFactoryId = 0;

  // 인기 유튜브 영상 (테슬라 관련)
  final List<Map<String, String>> _popularVideos = [
    {'id': 'dQw4w9WgXcQ', 'title': '테슬라 모델Y 풀 리뷰', 'channel': 'Tesla Korea'},
    {'id': '5qap5aO4i9A', 'title': '전기차 장거리 여행 꿀팁', 'channel': 'EV Trip'},
    {'id': 'kJQP7kiw5Fk', 'title': '테슬라 오토파일럿 체험기', 'channel': 'Tech Review'},
    {'id': '9bZkp7q19f0', 'title': '슈퍼차저 완충 브이로그', 'channel': 'Daily Tesla'},
  ];

  // 스트리밍 서비스 목록
  final List<Map<String, dynamic>> _streamingServices = [
    {
      'name': 'YouTube',
      'icon': Icons.play_circle_fill_rounded,
      'color': Color(0xFFFF0000),
      'url': 'https://m.youtube.com',
    },
    {
      'name': 'Netflix',
      'icon': Icons.movie_filter_rounded,
      'color': Color(0xFFE50914),
      'url': 'https://www.netflix.com',
    },
    {
      'name': 'Disney+',
      'icon': Icons.castle_rounded,
      'color': Color(0xFF113CCF),
      'url': 'https://www.disneyplus.com',
    },
    {
      'name': 'Wavve',
      'icon': Icons.waves_rounded,
      'color': Color(0xFF1D1D6D),
      'url': 'https://www.wavve.com',
    },
    {
      'name': 'Tving',
      'icon': Icons.tv_rounded,
      'color': Color(0xFFFF153C),
      'url': 'https://www.tving.com',
    },
    {
      'name': 'Coupang Play',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFE3004F),
      'url': 'https://www.coupangplay.com',
    },
  ];

  void _playVideo(String videoId) {
    final factoryName = 'youtube-player-$_viewFactoryId';
    ui_web.platformViewRegistry.registerViewFactory(
      factoryName,
      (int viewId) {
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.borderRadius = '16px';
        iframe.allow = 'autoplay; encrypted-media; fullscreen';
        return iframe;
      },
    );
    setState(() {
      _currentVideoId = factoryName;
      _isPlayerVisible = true;
      _viewFactoryId++;
    });
  }

  void _searchYouTube() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final url = 'https://m.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openService(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('엔터테인먼트'),
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
              // 1. YouTube 검색바
              _buildSearchBar(),
              const SizedBox(height: 20),

              // 2. 내장 유튜브 플레이어
              if (_isPlayerVisible) ...[
                _buildYouTubePlayer(),
                const SizedBox(height: 20),
              ],

              // 3. 스트리밍 서비스 그리드
              const Text('스트리밍 서비스',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildStreamingGrid(),
              const SizedBox(height: 28),

              // 4. 추천 영상
              const Text('추천 영상',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildVideoList(),
              const SizedBox(height: 28),

              // 5. 테슬라 시어터 모드 안내
              _buildTheaterModeCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'YouTube 검색...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _searchYouTube(),
            ),
          ),
          GestureDetector(
            onTap: _searchYouTube,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFFFF0000), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubePlayer() {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: HtmlElementView(viewType: _currentVideoId!),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _isPlayerVisible = false),
            child: const Text('닫기 ✕',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _streamingServices.length,
      itemBuilder: (context, index) {
        final service = _streamingServices[index];
        return GestureDetector(
          onTap: () => _openService(service['url']),
          child: Container(
            decoration: BoxDecoration(
              color: (service['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (service['color'] as Color).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(service['icon'] as IconData,
                    color: service['color'] as Color, size: 32),
                const SizedBox(height: 8),
                Text(service['name'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoList() {
    return Column(
      children: _popularVideos.map((video) {
        return GestureDetector(
          onTap: () => _playVideo(video['id']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // 썸네일
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://img.youtube.com/vi/${video['id']}/mqdefault.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_outline_rounded,
                        color: Colors.white70, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video['title']!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(video['channel']!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTheaterModeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE50914).withValues(alpha: 0.12),
            const Color(0xFF1D1D6D).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.theaters_rounded, color: Colors.orangeAccent, size: 22),
              SizedBox(width: 8),
              Text('🎬 테슬라 시어터 모드',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text('차량이 주차(P) 상태일 때만 영상을 재생할 수 있습니다.\n'
              '차량 브라우저에서 직접 접속하거나, 이 앱으로 캐스팅하세요.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip('주차 중만 가능', Icons.local_parking_rounded),
              const SizedBox(width: 8),
              _buildChip('Wi-Fi 권장', Icons.wifi_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
