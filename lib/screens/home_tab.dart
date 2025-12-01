import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import 'wardrobe_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // 기준치 (RDI) - 20대 평균 기준
  final double limitSodium = 2000.0;
  final double limitCarbo = 324.0;
  final double limitFat = 54.0; // 지방 권장량
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('diet_logs')
            .where('date', isEqualTo: _todayString)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("데이터 로드 실패"));
          
          final docs = snapshot.data?.docs ?? [];
          
          // 영양소 합계 계산
          Map<String, double> nutrientSum = {
            'sodium': 0, 'carbo': 0, 'trans_fat': 0, 'kcal': 0, 'fat': 0
          };
          bool hadBreakfast = false; // 아침 식사 여부
          bool hadLunch = false;
          bool hadDinner = false;

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
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

          // 상태 판정 로직
          String charState = "normal";
          String stateMessage = "오늘 컨디션 최고! 💪";
          
          int hour = DateTime.now().hour;

          // 1순위: 아픔
          if (nutrientSum['sodium']! > limitSodium) {
            charState = "sick";
            stateMessage = "으악! 너무 짜게 먹었어요... 몸이 부었어요 🤢";
          } 
          // 2순위: 뚱뚱보
          else if (nutrientSum['fat']! > limitFat || nutrientSum['trans_fat']! > limitTransFat) {
            charState = "obese";
            stateMessage = "기름진 음식을 너무 많이 먹었어요... 몸이 무거워요 🐷";
          } 
          // 3순위: 배고픔 (아침, 점심, 저녁 체크 추가)
          else if (
            (hour >= 10 && !hadBreakfast) || // 10시 지났는데 아침 안 먹음
            (hour >= 13 && !hadLunch) ||     // 13시 지났는데 점심 안 먹음
            (hour >= 20 && !hadDinner)       // 20시 지났는데 저녁 안 먹음
          ) {
            charState = "hungry";
            stateMessage = "배고파요... 밥 언제 주나요? 🤤";
          }

          // 위험도 계산
          double hbpRisk = (nutrientSum['sodium']! / limitSodium).clamp(0.0, 1.0);
          double diabetesRisk = (nutrientSum['carbo']! / limitCarbo).clamp(0.0, 1.0);
          double obesityRisk = (nutrientSum['fat']! / limitFat).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. 캐릭터 영역
                Expanded(
                  flex: 3,
                  child: Center(
                    // ★ [수정 핵심] Stack을 감싸는 Container에 크기를 지정해서 터치 영역 확보
                    child: SizedBox(
                      width: 340, // 넉넉한 너비 (버튼이 들어갈 공간 확보)
                      child: Stack(
                        alignment: Alignment.center,
                        // clipBehavior: Clip.none, // 이제 안 써도 됨 (영역을 넓혔으므로)
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 실제 이미지 표시 함수 호출
                              _buildRealCharacterImage(user.gender, charState),
                              
                              const SizedBox(height: 20),
                              Text(
                                user.name.isEmpty ? "이름없음" : user.name,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getStateColor(charState).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: _getStateColor(charState)),
                                ),
                                child: Text(
                                  stateMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          // ★ [수정] 포인트샵 버튼 위치 조정 (박스 안쪽 오른쪽 끝으로)
                          Positioned(
                            right: 0, // 오른쪽 끝에 딱 붙임 (잘리지 않음)
                            bottom: 80, // 높이 조정
                            child: Column(
                              children: [
                                FloatingActionButton(
                                  heroTag: "shopBtn", // 태그 추가 (에러 방지)
                                  onPressed: () {
                                    // 페이지 이동
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WardrobeScreen()));
                                  },
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  child: const Icon(Icons.checkroom, color: Colors.purple, size: 28),
                                ),
                                const SizedBox(height: 5),
                                const Text("포인트샵", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. 위험도 UI
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
                          _buildRiskBar("비만 위험 (지방)", obesityRisk, Colors.purple),
                          
                          const SizedBox(height: 15),
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

  // 실제 이미지 로드 함수
  Widget _buildRealCharacterImage(String gender, String state) {
    String genderPrefix = (gender == 'M') ? 'male' : 'female';
    String imagePath = 'assets/images/${genderPrefix}_$state.png';

    return Image.asset(
      imagePath,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Column(
          children: [
            Icon(Icons.broken_image, size: 80, color: Colors.grey),
            const Text("이미지 준비중", style: TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }

  Widget _buildPointBadge(int point) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.cookie, color: Colors.brown, size: 20),
          const SizedBox(width: 5),
          Text("$point P", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Color _getStateColor(String state) {
    if (state == "sick") return Colors.red;
    if (state == "obese") return Colors.purple;
    if (state == "hungry") return Colors.grey;
    return Colors.blue;
  }

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
          color: value > 0.8 ? Colors.red : color,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}