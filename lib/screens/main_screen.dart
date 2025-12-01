import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ★ 앱 종료 기능을 위해 추가
import 'home_tab.dart';
import 'diet_tab.dart'; 
import 'shop_tab.dart'; 
import 'friend_tab.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 번호 (0: 홈)

  // 탭별 화면 리스트
  final List<Widget> _tabs = [
    const HomeTab(),   // 0. 홈
    const DietTab(),   // 1. 식단
    const ShopTab(),   // 2. 상점
    const FriendTab(), // 3. 친구
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로 가기를 눌렀을 때 자동으로 화면이 닫히지 않게 막음
      onPopInvoked: (didPop) async {
        if (didPop) return; // 이미 닫혔으면 무시

        if (_selectedIndex != 0) {
          // 1. 홈 탭이 아니면 -> 홈 탭으로 이동
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          // 2. 이미 홈 탭이면 -> 앱 종료
          // (Windows에서는 창이 닫히고, 안드로이드에서는 앱이 종료됨)
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // 선택된 화면 보여주기
        body: _tabs[_selectedIndex], 
        
        // 하단 네비게이션 바
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // 탭이 4개 이상일 때 필수
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue, // 선택된 아이콘 색
          unselectedItemColor: Colors.grey, // 안 선택된 아이콘 색
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.rice_bowl), label: '식단'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'), // 포인트샵으로 이름 변경 가능
            BottomNavigationBarItem(icon: Icon(Icons.people), label: '친구'),
          ],
        ),
      ),
    );
  }
}