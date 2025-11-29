import 'package:flutter/material.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 아이템 목록
    final items = [
      {"name": "멋쟁이 모자", "price": 500, "icon": Icons.hiking},
      {"name": "황금 덤벨", "price": 1000, "icon": Icons.fitness_center},
      {"name": "파티 안경", "price": 300, "icon": Icons.masks},
      {"name": "운동화", "price": 700, "icon": Icons.directions_run},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("COOK-KEY 상점 🛍️")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2열
          childAspectRatio: 0.8, // 세로로 조금 길게
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
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 10),
                Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${item['price']} C", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // 구매 로직 (나중에 구현)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("구매 완료! (개발 중)")));
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