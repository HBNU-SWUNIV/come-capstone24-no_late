import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanbat_capstone/providers/category_provider.dart';
import 'package:hanbat_capstone/providers/schedulesettings_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:hanbat_capstone/services/notification_service.dart';
import 'package:hanbat_capstone/screen/auth_screen.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:provider/provider.dart';
import 'package:hanbat_capstone/providers/auth_provider.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:hanbat_capstone/providers/statistics_provider.dart';


final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase 오류 메시지 한국어 설정
  FirebaseAuth.instance.setLanguageCode("ko");

  // 국제화 초기화
  await initializeDateFormatting('ko_KR', null);

  final notificationService = NotificationService();
  await notificationService.init();


  final authProvider = AuthProvider();
  await authProvider.loadUser();  // 사용자 정보 로드



  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleSettingsProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MyApp(notificationService: notificationService,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
              backgroundColor: Colors.lightBlue[900],
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )
          ),
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final ThemeData theme;

  MyApp({required this.notificationService, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanbat Capstone',
      theme: theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: globalNavigatorKey,
      home: AuthWrapper(notificationService: notificationService),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final NotificationService notificationService;

  AuthWrapper({required this.notificationService});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            _isInitialized = false;
            return AuthScreen();
          } else {
            if (!_isInitialized) {
              // 사용자가 로그인된 상태에서 처음 한 번만 이벤트 알림을 초기화합니다.
              widget.notificationService.eventNotificationFromFirestore();
              _isInitialized = true;
            }
            return RootScreen(notificationService: widget.notificationService);
          }
        }
        // 연결 상태가 활성화되지 않았을 때 로딩 표시
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

