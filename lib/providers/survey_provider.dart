import 'package:flutter/foundation.dart';
import '../models/survey_question_model.dart';
import '../utils/survey_questions.dart';

class SurveyProvider with ChangeNotifier {
  final List<SurveyQuestion> _questions = SurveyQuestions.getQuestions();
  final Map<String, dynamic> _answers = {};
  int _currentPageIndex = 0;
  bool _isCompleted = false;

  List<SurveyQuestion> get questions => _questions;
  Map<String, dynamic> get answers => _answers;
  int get currentPageIndex => _currentPageIndex;
  bool get isCompleted => _isCompleted;
  int get totalQuestions => _questions.length;

  /// 현재 질문 가져오기
  SurveyQuestion? getCurrentQuestion() {
    if (_currentPageIndex >= 0 && _currentPageIndex < _questions.length) {
      return _questions[_currentPageIndex];
    }
    return null;
  }

  /// 답변 저장
  void setAnswer(String questionId, dynamic answer) {
    _answers[questionId] = answer;
    notifyListeners();
  }

  /// 현재 질문의 답변 가져오기
  dynamic getAnswer(String questionId) {
    return _answers[questionId];
  }

  /// 다음 페이지로 이동
  void nextPage() {
    if (_currentPageIndex < _questions.length - 1) {
      _currentPageIndex++;
      notifyListeners();
    } else {
      // 마지막 질문이면 완료 처리
      completeSurvey();
    }
  }

  /// 이전 페이지로 이동
  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex--;
      notifyListeners();
    }
  }

  /// 특정 페이지로 이동
  void goToPage(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// 설문 완료
  void completeSurvey() {
    _isCompleted = true;
    notifyListeners();
  }

  /// 설문 점수 계산
  /// 만점 100점에서 시작하여 건강에 좋지 않은 선택지마다 감점
  /// 최악의 선택지만 골랐을 경우 20점이 되도록 설정
  int calculateScore() {
    int score = 100; // 만점 100점에서 시작

    // 각 답변에 따라 점수 감점 또는 가점
    for (var entry in _answers.entries) {
      final questionId = entry.key;
      final answer = entry.value;

      switch (questionId) {
        case 'eating_out_frequency':
          // 외식 빈도가 높을수록 감점 (0회: 0점 감점, 7회 이상: 13점 감점)
          final options = ['0회', '1-2회', '3-4회', '5-6회', '7회 이상'];
          final index = options.indexOf(answer.toString());
          if (index >= 0) {
            // 최선(0회)은 감점 없음, 최악(7회 이상)은 13점 감점
            final penalty = (index * 13) ~/ (options.length - 1);
            score -= penalty;
          }
          break;

        case 'delivery_frequency':
          // 배달 빈도가 높을수록 감점 (0회: 0점 감점, 7회 이상: 13점 감점)
          final options = ['0회', '1-2회', '3-4회', '5-6회', '7회 이상'];
          final index = options.indexOf(answer.toString());
          if (index >= 0) {
            // 최선(0회)은 감점 없음, 최악(7회 이상)은 13점 감점
            final penalty = (index * 13) ~/ (options.length - 1);
            score -= penalty;
          }
          break;

        case 'dietary_habits':
          // 식습관에 따라 감점 (다중 선택 가능)
          if (answer is List) {
            // 선택된 항목들에 대해 각각 감점 적용
            for (var habit in answer) {
              if (habit == '규칙적으로 3끼 챙겨먹음') {
                // 최선: 감점 없음 (0점 감점)
              } else if (habit == '아침 결식이 많음') {
                score -= 10; // 5점 감점
              } else if (habit == '간편식 위주') {
                score -= 10; // 10점 감점
              } else if (habit == '불규칙한 시간에 먹음') {
                score -= 10; // 최악: 20점 감점
              } else if (habit == '다이어트 중') {
                score -= 10; // 10점 감점
              }
            }
          } else {
            // 단일 선택인 경우 (하위 호환성)
            if (answer == '규칙적으로 3끼 챙겨먹음') {
              // 최선: 감점 없음
            } else if (answer == '아침 결식이 많음') {
              score -= 10;
            } else if (answer == '간편식 위주') {
              score -= 10;
            } else if (answer == '불규칙한 시간에 먹음') {
              score -= 10;
            } else if (answer == '다이어트 중') {
              score -= 10;
            }
          }
          break;

        case 'meals_per_day':
          // 하루 식사 횟수에 따라 감점
          if (answer == '3끼') {
            // 최선: 감점 없음
          } else if (answer == '2끼') {
            score -= 5; // 5점 감점
          } else if (answer == '1끼') {
            score -= 11; // 최악: 11점 감점
          }
          break;

        case 'cooking_tools':
          // 조리도구가 없을수록 감점
          if (answer is List) {
            if (answer.isEmpty || answer.contains('없음')) {
              score -= 9; // 최악: 조리도구 없음 9점 감점
            } else {
              // 조리도구가 많을수록 좋지만, 감점은 하지 않음 (기본 점수 유지)
              // 조리도구가 있으면 추가 감점 없음
            }
          }
          break;

        case 'can_use_fire':
          // 불 사용 불가능하면 감점
          if (answer == false) {
            score -= 5; // 5점 감점
          }
          // 불 사용 가능하면 감점 없음
          break;

        case 'refrigerator_size':
          // 냉장고가 작을수록 감점
          if (answer == '소형') {
            score -= 9; // 최악: 9점 감점
          } else if (answer == '중형') {
            score -= 5; // 5점 감점
          }
          // 대형은 감점 없음
          break;
      }
    }

    // 점수는 0점 이하로 내려가지 않도록 제한
    return score.clamp(0, 100);
  }

  /// 페르소나 유형 결정
  String determinePersonaType() {
    final score = calculateScore();

    // 점수에 따라 페르소나 결정
    if (score >= 70) {
      return '건강한 식습관 유지형';
    } else if (score >= 40) {
      return '개선 가능형';
    } else {
      return '개선 필요형';
    }
  }

  /// 설문 결과 생성
  SurveyResult getSurveyResult(String userId) {
    return SurveyResult(
      userId: userId,
      responses: _answers.entries.map((entry) {
        return SurveyResponse(questionId: entry.key, answer: entry.value);
      }).toList(),
      completedAt: DateTime.now(),
      personaType: determinePersonaType(),
    );
  }

  /// 초기화
  void reset() {
    _answers.clear();
    _currentPageIndex = 0;
    _isCompleted = false;
    notifyListeners();
  }
}
