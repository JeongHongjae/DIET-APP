import 'package:flutter/material.dart';

class FriendTab extends StatelessWidget {
  const FriendTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 친구 더미 데이터 (아빠, 엄마, 동생)
    // 상태: normal, sick, hungry, obese
    final List<Map<String, dynamic>> friends = [
      {
        "name": "우리 아빠",
        "gender": "M",
        "state": "obese", // 아빠는 뚱뚱보 상태
        "message": "요즘 회식이 너무 잦네... 허허 😅",
        "nutrients": {
          'kcal': 2800.0, 'carbo': 400.0, 'protein': 60.0, 'fat': 90.0,
          'vit_c': 20.0, 'calcium': 400.0, 'sodium': 3500.0, 'trans_fat': 1.2
        }
      },
      {
        "name": "우리 엄마",
        "gender": "F",
        "state": "normal", // 엄마는 건강함
        "message": "오늘도 등산 다녀왔어! 상쾌하다 🏔️",
        "nutrients": {
          'kcal': 1800.0, 'carbo': 250.0, 'protein': 70.0, 'fat': 40.0,
          'vit_c': 150.0, 'calcium': 800.0, 'sodium': 1500.0, 'trans_fat': 0.0
        }
      },
      {
        "name": "내 동생",
        "gender": "M",
        "state": "hungry", // 동생은 밥을 굶음
        "message": "게임하느라 밥 먹는 거 까먹음... 🎮",
        "nutrients": {
          'kcal': 500.0, 'carbo': 80.0, 'protein': 10.0, 'fat': 10.0,
          'vit_c': 5.0, 'calcium': 100.0, 'sodium': 600.0, 'trans_fat': 0.0
        }
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("친구 목록 👥"), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildFriendCard(context, friends[index]);
        },
      ),
    );
  }

  // 친구 카드 위젯 (누르면 펼쳐짐)
  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // 펼쳤을 때 선 없애기
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(10),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          
          // 1. 헤더: 캐릭터 이미지 + 이름 + 상태 메시지
          leading: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _buildRealCharacterImage(friend['gender'], friend['state']),
            ),
          ),
          title: Text(friend['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(friend['message'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          
          // 2. 펼쳐졌을 때 내용: 일일 영양소 그래프
          children: [
            const Divider(),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("오늘의 섭취량 훔쳐보기 👀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 15),
            _buildNutrientInfo(friend['nutrients']),
          ],
        ),
      ),
    );
  }

  // 영양 정보 표시 위젯 (식단 탭 로직 재사용)
  Widget _buildNutrientInfo(Map<String, double> nutrients) {
    // 친구들의 권장량(RDI)은 대략적인 평균치로 잡음
    final rdi = {
      'kcal': 2500.0, 'carbo': 324.0, 'protein': 55.0, 'fat': 54.0,
      'vit_c': 100.0, 'sodium': 2000.0, 'trans_fat': 0.5
    };

    return Column(
      children: [
        // 3대 영양소 (원형)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroCircle("탄수화물", nutrients['carbo']!, rdi['carbo']!, Colors.purple),
            _buildMacroCircle("단백질", nutrients['protein']!, rdi['protein']!, Colors.blue),
            _buildMacroCircle("지방", nutrients['fat']!, rdi['fat']!, Colors.orange),
          ],
        ),
        const SizedBox(height: 20),
        
        // 상세 영양소 (막대)
        _buildMicroBar("비타민 C", nutrients['vit_c']!, rdi['vit_c']!, "mg"),
        _buildMicroBar("나트륨", nutrients['sodium']!, rdi['sodium']!, "mg", isLimit: true),
        _buildMicroBar("트랜스지방", nutrients['trans_fat']!, rdi['trans_fat']!, "g", isLimit: true),
      ],
    );
  }

  // --- 아래는 그래프 그리는 헬퍼 함수들 (DietTab과 디자인 통일) ---

  Widget _buildRealCharacterImage(String gender, String state) {
    String genderPrefix = (gender == 'M') ? 'male' : 'female';
    String imagePath = 'assets/images/${genderPrefix}_$state.png';

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.face, color: Colors.grey),
    );
  }

  Widget _buildMacroCircle(String label, double current, double goal, Color color) {
    double percent = (current / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 45, height: 45,
              child: CircularProgressIndicator(value: percent, color: color, backgroundColor: Colors.grey[200], strokeWidth: 4),
            ),
            Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMicroBar(String label, double current, double goal, String unit, {bool isLimit = false}) {
    double percent = (current / goal).clamp(0.0, 1.0);
    Color barColor = isLimit && percent >= 1.0 ? Colors.red : Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(value: percent, color: barColor, backgroundColor: Colors.grey[200], minHeight: 6, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 50, child: Text("${current.toInt()}$unit", style: const TextStyle(fontSize: 10), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}