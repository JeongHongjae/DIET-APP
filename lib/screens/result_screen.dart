import 'package:flutter/material.dart';
import 'character_creation_screen.dart'; // ★ 우리가 만든 캐릭터 생성 화면으로 연결

class ResultScreen extends StatelessWidget {
  final int score;
  final String personaType;

  const ResultScreen({
    super.key,
    required this.score,
    required this.personaType,
  });

  @override
  Widget build(BuildContext context) {
    // 간단한 로직으로 변경 (Utils 파일 없어도 되게)
    final bool hasRisk = score < 50; 
    final String riskMessage = hasRisk ? "영양 불균형이 심각해요! 관리가 필요합니다." : "건강 관리를 잘하고 계시네요!";

    return Scaffold(
      appBar: AppBar(
        title: const Text('설문 결과'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // 1. 캐릭터 이미지 영역
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 점수에 따른 아이콘 변화
                        Icon(
                          hasRisk ? Icons.sentiment_very_dissatisfied : Icons.sentiment_very_satisfied,
                          size: 80,
                          color: hasRisk ? Colors.grey : Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasRisk ? '위험 상태' : '건강한 상태',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. 건강 위험도 경고 박스 (점수가 낮을 때만 표시)
            if (hasRisk) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        riskMessage,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // 3. 점수 표시
            _buildInfoCard(context, title: '당신의 점수', content: '$score점', isScore: true),
            
            const SizedBox(height: 24),
            
            // 4. 페르소나 타입 표시
            _buildInfoCard(context, title: '당신의 유형', content: personaType, description: _getPersonaDescription(personaType)),
            
            const SizedBox(height: 40),
            
            // 5. 시작 버튼 (여기가 중요!)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // ★ [핵심 수정] Provider 에러 없애고, 캐릭터 생성 화면으로 이동!
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      // 페르소나 정보를 넘겨주면서 이동
                      builder: (context) => CharacterCreationScreen(persona: personaType),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('캐릭터 생성하러 가기', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 카드 디자인 재사용 함수
  Widget _buildInfoCard(BuildContext context, {required String title, required String content, String? description, bool isScore = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              content,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isScore && (score < 50) ? Colors.red : Colors.blueAccent,
                    fontSize: 28,
                  ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 16),
              Text(description, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  String _getPersonaDescription(String type) {
    // 간단한 설명 반환
    return '맞춤형 식단 추천을 받아보세요.';
  }
}