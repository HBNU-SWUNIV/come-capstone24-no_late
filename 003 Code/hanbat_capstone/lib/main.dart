import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

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
      home: RootScreen()
    )
  );
}