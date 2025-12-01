import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    // 임시 아이템 데이터
    final List<Map<String, dynamic>> items = [
      {"name": "빨간 모자", "price": 500, "icon": Icons.hiking},
      {"name": "선글라스", "price": 300, "icon": Icons.visibility},
      {"name": "황금 목걸이", "price": 1000, "icon": Icons.monetization_on},
      {"name": "운동화", "price": 700, "icon": Icons.directions_run},
      {"name": "정장", "price": 1500, "icon": Icons.business_center},
      {"name": "파티 가면", "price": 200, "icon": Icons.masks},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("나만의 옷장 👕"),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(20)),
              child: Text("${user.point} P", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'], size: 60, color: Colors.blueAccent), // 나중엔 이미지로 교체 가능
                const SizedBox(height: 10),
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text("${item['price']} C", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 구매 로직 (간단하게 포인트만 차감하는 시늉)
                    if (user.point >= item['price']) {
                      // 실제로는 UserProvider에 point 차감 함수를 만들어야 함
                      // user.deductPoint(item['price']); 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("구매 성공! (착용 기능은 준비중)")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("포인트가 부족해요! 밥을 더 잘 챙겨드세요.")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text("구매"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}