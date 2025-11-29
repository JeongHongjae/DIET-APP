import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 임시 데이터 (나중에 Provider나 Firebase에서 가져올 것)
  int cookiePoint = 1500;
  double healthScore = 40; // 0~100 (낮으면 아픔)
  double diabetesRisk = 0.8; // 당뇨 위험도 (0.0 ~ 1.0)
  double hbpRisk = 0.3; // 고혈압 위험도

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 앱바 (포인트 표시용)
      appBar: AppBar(
        title: const Text("내 캐릭터"),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cookie, color: Colors.brown, size: 20),
                  const SizedBox(width: 5),
                  Text("$cookiePoint P", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 캐릭터 영역 (건강 상태에 따라 이미지 변경)
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 캐릭터 이미지 (임시로 아이콘 사용, 나중에 이미지로 교체)
                    Icon(
                      healthScore < 50 ? Icons.sick : Icons.sentiment_satisfied_alt,
                      size: 150,
                      color: healthScore < 50 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    // 말풍선 (상태 메시지)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        healthScore < 50 ? "배고파요... 밥 좀 줘..." : "오늘 컨디션 최고!",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. 건강 위험도 UI (당뇨, 고혈압)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⚠️ 건강 위험 경보", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildRiskBar("당뇨 위험", diabetesRisk, Colors.orange),
                    const SizedBox(height: 15),
                    _buildRiskBar("고혈압 위험", hbpRisk, Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 위험도 게이지 바 만드는 함수
  Widget _buildRiskBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${(value * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value, // 0.0 ~ 1.0
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}