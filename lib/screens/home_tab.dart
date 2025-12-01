import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 기준치 (RDI) - 20대 평균 기준
  final double limitSodium = 2000.0;
  final double limitCarbo = 324.0;
  final double limitFat = 54.0; // ★ [추가] 지방 권장량
  final double limitTransFat = 0.5;

  // 오늘 날짜 구하기
  String get _todayString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("내 캐릭터"),
        actions: [
          _buildPointBadge(user.point),
        ],
      ),
      // ★ Firestore 실시간 데이터 구독 (오늘 날짜)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('diet_logs')
            .where('date', isEqualTo: _todayString)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("데이터 로드 실패"));
          
          final docs = snapshot.data?.docs ?? [];
          
          // 1. 영양소 합계 및 식사 여부 계산
          Map<String, double> nutrientSum = {
            'sodium': 0, 'carbo': 0, 'trans_fat': 0, 'kcal': 0, 'fat': 0
          };
          bool hadBreakfast = false;
          bool hadLunch = false;
          bool hadDinner = false;

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            // 안전하게 숫자 변환 (DB에 문자로 저장되어 있을 수도 있으므로)
            nutrientSum['sodium'] = nutrientSum['sodium']! + (double.tryParse(data['sodium']?.toString() ?? "0") ?? 0);
            nutrientSum['carbo'] = nutrientSum['carbo']! + (double.tryParse(data['carbo']?.toString() ?? "0") ?? 0);
            nutrientSum['trans_fat'] = nutrientSum['trans_fat']! + (double.tryParse(data['trans_fat']?.toString() ?? "0") ?? 0);
            nutrientSum['kcal'] = nutrientSum['kcal']! + (double.tryParse(data['kcal']?.toString() ?? "0") ?? 0);
            nutrientSum['fat'] = nutrientSum['fat']! + (double.tryParse(data['fat']?.toString() ?? "0") ?? 0);

            String type = data['mealType'] ?? '';
            if (type == 'breakfast') hadBreakfast = true;
            if (type == 'lunch') hadLunch = true;
            if (type == 'dinner') hadDinner = true;
          }

          // 2. 캐릭터 상태 판정 로직 (Game Rules)
          String charState = "normal"; // normal, hungry, sick
          String stateMessage = "오늘 컨디션 최고! 💪";
          
          int hour = DateTime.now().hour;

          // (1) 아픔 체크 (나트륨/트랜스지방 과다)
          if (nutrientSum['sodium']! > limitSodium) {
            charState = "sick";
            stateMessage = "으악! 너무 짜게 먹었어요... 몸이 부었어요 🤢";
          } else if (nutrientSum['trans_fat']! > limitTransFat) {
            charState = "sick";
            stateMessage = "기름진 음식 그만! 혈관이 아파요 🚑";
          } 
          // (2) 배고픔 체크 (시간 지났는데 밥 안 먹음)
          // 점심 시간(13시) 지났는데 점심 안 먹음 OR 저녁 시간(20시) 지났는데 저녁 안 먹음
          else if ((hour >= 13 && !hadLunch) || (hour >= 20 && !hadDinner)) {
            charState = "hungry";
            stateMessage = "배고파요... 밥 언제 주나요? 🤤";
          }

          // 3. 위험도 계산 (0.0 ~ 1.0, 1.0이 100%)
          double hbpRisk = (nutrientSum['sodium']! / limitSodium).clamp(0.0, 1.0); // 고혈압(나트륨)
          double diabetesRisk = (nutrientSum['carbo']! / limitCarbo).clamp(0.0, 1.0); // 당뇨(탄수화물)
          double obesityRisk = (nutrientSum['fat']! / limitFat).clamp(0.0, 1.0); // ★ 비만(지방)

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 캐릭터 영역 (상단)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 상태에 따른 이미지 표시
                        _buildCharacterImage(user.gender, charState),
                        const SizedBox(height: 20),
                        Text(
                          user.name.isEmpty ? "이름없음" : user.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        // 말풍선
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStateColor(charState).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _getStateColor(charState)),
                          ),
                          child: Text(
                            stateMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 위험도 UI 영역 (하단)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("⚠️ 나의 건강 위험도", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _buildRiskBar("고혈압 위험 (나트륨)", hbpRisk, Colors.red),
                          const SizedBox(height: 15),
                          _buildRiskBar("당뇨 위험 (탄수화물)", diabetesRisk, Colors.orange),
                          const SizedBox(height: 15),
                          // ★ [추가] 비만 위험도 그래프
                          _buildRiskBar("비만 위험 (지방)", obesityRisk, Colors.purple),
                          
                          const SizedBox(height: 15),
                          // 하나라도 위험 수치(80%) 넘으면 경고 문구 표시
                          if (hbpRisk > 0.8 || diabetesRisk > 0.8 || obesityRisk > 0.8)
                            const Text("🚨 경고: 식습관 개선이 시급합니다!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 상단 포인트 배지 위젯
  Widget _buildPointBadge(int point) {
    return Center(
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
            Text("$point P", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 캐릭터 이미지 위젯
  Widget _buildCharacterImage(String gender, String state) {
    IconData icon;
    Color color;

    if (state == "sick") {
      icon = Icons.sick; // 아픔
      color = Colors.green;
    } else if (state == "hungry") {
      icon = Icons.sentiment_dissatisfied; // 배고픔
      color = Colors.grey;
    } else {
      // 건강함
      icon = (gender == 'M') ? Icons.face : Icons.face_3;
      color = (gender == 'M') ? Colors.blue : Colors.pink;
    }

    return Icon(icon, size: 150, color: color);
  }

  // 상태별 색상 반환
  Color _getStateColor(String state) {
    if (state == "sick") return Colors.red;
    if (state == "hungry") return Colors.grey;
    return Colors.blue;
  }

  // 위험도 게이지 바 위젯
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
          value: value,
          backgroundColor: Colors.grey[200],
          color: value > 0.8 ? Colors.red : color, // 80% 넘으면 무조건 빨간색 경고
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}