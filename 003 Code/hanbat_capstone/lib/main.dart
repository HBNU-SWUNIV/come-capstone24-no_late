import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {

  // await dotenv.load(fileName: ".env");

  // 플러터 프레임워크가 준비될 때까지 대기
  WidgetsFlutterBinding.ensureInitialized();

  // intl 패키지 초기화 (다국어화)
  await initializeDateFormatting();

  // 파이어베이스 프로젝트 설정
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MaterialApp(
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        )
      ),
      home: RootScreen(),
    )
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('OpenAI API Key: ${dotenv.env['OPENAI_API_KEY']}'),
        ),
      ),
    );
  }
}