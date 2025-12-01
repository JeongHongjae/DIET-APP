import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'firebase_options.dart';
import 'providers/user_provider.dart'; 
import 'screens/survey_screen.dart'; 
import 'screens/landing_screen.dart';
import 'providers/survey_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/party_provider.dart';
import 'providers/character_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SurveyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diet App',
      theme: ThemeData(
        // ... theme 설정
      ),
      home: const LandingScreen(), // [수정] SurveyScreen -> LandingScreen으로 변경
    );
  }
  }