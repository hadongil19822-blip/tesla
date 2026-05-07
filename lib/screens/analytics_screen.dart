import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운행 및 통합 분석'),
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
              _buildSectionTitle('팬텀 드레인 (주차 중 배터리 소모)'),
              const SizedBox(height: 16),
              _buildChartPlaceholder(
                '최근 7일 소모량 추이',
                CupertinoIcons.graph_square,
                Colors.orangeAccent,
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('이번 달 충전 요금'),
              const SizedBox(height: 16),
              _buildSummaryCard(
                icon: CupertinoIcons.money_dollar_circle_fill,
                title: '총 45,200원',
                subtitle: '슈퍼차저 3회, 집밥 12회',
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('소모품 교환 알림'),
              const SizedBox(height: 16),
              _buildSummaryCard(
                icon: CupertinoIcons.wrench_fill,
                title: '타이어 위치 교환',
                subtitle: '권장 주행거리(10,000km) 도달',
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChartPlaceholder(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          // 가상의 그래프 자리
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(40),
                _buildBar(60),
                _buildBar(30),
                _buildBar(80),
                _buildBar(50),
                _buildBar(20),
                _buildBar(90),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
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
          )
        ],
      ),
    );
  }
}
