import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _name = "";
  String _gender = "M";
  String _persona = "";
  int _point = 0;
  bool _isInitialized = false; // 데이터 로드 여부

  // 데이터 가져오기 (Getters)
  String get name => _name;
  String get gender => _gender;
  String get persona => _persona;
  int get point => _point;
  bool get isInitialized => _isInitialized;

  // 생성자: 앱 시작 시 자동으로 데이터 불러오기 시도
  UserProvider() {
    loadUserInfo();
  }

  // [1] 정보 저장 (캐릭터 생성 시 호출)
  Future<void> setUserInfo(String inputName, String inputGender, String inputPersona) async {
    _name = inputName;
    _gender = inputGender;
    _persona = inputPersona;
    _isInitialized = true;
    notifyListeners(); // 화면 즉시 갱신

    // 디스크에 영구 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', inputName);
    await prefs.setString('user_gender', inputGender);
    await prefs.setString('user_persona', inputPersona);
    await prefs.setInt('user_point', _point);
    await prefs.setBool('is_setup_complete', true);
  }

  // [2] 포인트 추가 및 저장 (식단 기록 시 호출)
  Future<void> addPoint(int amount) async {
    _point += amount;
    notifyListeners(); // 화면 즉시 갱신

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_point', _point); // 변경된 포인트 저장
  }

  // [3] 정보 불러오기 (앱 켤 때 실행)
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('is_setup_complete')) {
      return; // 저장된 데이터 없음
    }

    _name = prefs.getString('user_name') ?? "";
    _gender = prefs.getString('user_gender') ?? "M";
    _persona = prefs.getString('user_persona') ?? "";
    _point = prefs.getInt('user_point') ?? 0;
    _isInitialized = true;

    notifyListeners();
  }

  // [4] 로그아웃/초기화 (테스트용)
  Future<void> clearUser() async {
    _name = "";
    _gender = "M";
    _persona = "";
    _point = 0;
    _isInitialized = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}