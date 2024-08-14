import 'dart:async';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'package:hanbat_capstone/services/notification_service.dart';
import 'screen/auth_screen.dart';


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

  // 알림 설정 **************************************************
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.eventNotificationFromFirestore(); // // 앱 시작 시 Firestore에서 이벤트를 가져와 알림 예약
  //************************************************************

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {

  final NotificationService notificationService;
  MyApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        // 다른 provider들...
      ],
      child: MaterialApp(
        theme: ThemeData(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
            )
        ),
        home: RootScreen(notificationService: notificationService),
        // home: AuthWrapper(notificationService: notificationService),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final NotificationService notificationService;

  AuthWrapper({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return AuthScreen();
          }
          return RootScreen(notificationService: notificationService);
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}