import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hanbat_capstone/model/event_model.dart';
import 'package:hanbat_capstone/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/**
 * 알림 기능
 */
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  /**
   * 초기화 메소드
   */
  Future<void> init() async {
    // android 설정
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    // ios 설정
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true, // 알림 표시 권한
      requestBadgePermission: true, // 앱 아이콘 배지 업데이트 권한
      requestSoundPermission: true, // 알림 소리 권한
    );

    // 여러 플랫폼을 지원하기 위한 초기설정
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      //macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  }

  /**
   * firestore에서 이벤트 데이터를 가져와 알림을 설정하는 메소드
   */
  Future<void> eventNotificationFromFirestore() async {
    DateTime now = DateTime.now();
    String fmtNowDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(now);
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    QuerySnapshot snapshot = await firestore.collection('events')
        .where('userId', isEqualTo: userId)
        .where('eventSttTime', isGreaterThan: fmtNowDate)
        .get();

    for(var doc in snapshot.docs) {
      EventModel event = EventModel.fromMap(doc.data() as Map<String, dynamic>);

      if(event.eventSttTime != null){
        // 알림 시간 설정 (이벤트 시작 시간 30분 전으로 디폴트 셋팅)
        DateTime notificationTime = event.eventSttTime!.subtract(Duration(minutes: 30));

        await eventNotification(
          event.eventId.hashCode,
          event.eventTitle,
          event.eventContent ?? "곧 이벤트가 시작됩니다.",
          notificationTime,
        );
      }
    }
  }

  Future<void> eventNotification(int id, String title, String body, DateTime eventNotificationDateTime) async {

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'schedule app', // 채널 ID
      '일정관리 앱', // 채널 이름
      channelDescription: '일정관리 앱',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    final darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,  // 알림 표시
      presentBadge: true,  // 앱 배지 표시
      presentSound: true,  // 알림 소리 재생
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        eventNotificationDateTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 특정 시간에 알림 설정
    );

  }
}