import 'package:flutter/material.dart';

class FriendTab extends StatelessWidget {
  const FriendTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "친구 목록 화면\n(추후 개발 예정)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),
    );
  }
}