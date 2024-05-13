import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule_CRUD {
  int day;
  String time;
  String planedwork;
  String unplanedwork;

  Schedule_CRUD({required this.day, required this.time, required this.planedwork, required this.unplanedwork});

  //fromDocument와 toMap 메서드는 Firestore 문서와 Schedule_CRUD 객체 간의 변환을 처리
  factory Schedule_CRUD.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule_CRUD(
      day: data['day'],
      time: data['time'],
      planedwork: data['planedwork'],
      unplanedwork: data['unplanedwork'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'time': time,
      'planedwork': planedwork,
      'unplanedwork': unplanedwork,
    };
  }


  // Create
  //createSchedule 메서드는 Firestore의 'schedules' 컬렉션에 새 문서를 만들고 일정 데이터를 저장
  static Future<void> createSchedule(Schedule_CRUD schedule) async {
    final scheduleRef = FirebaseFirestore.instance.collection('schedules').doc();
    await scheduleRef.set(schedule.toMap());
  }


  // Read
  //getSchedulesByDate 메서드는 'schedules' 컬렉션에서 특정 날짜의 모든 일정을 조회
  static Future<List<Schedule_CRUD>> getSchedulesByDate(DateTime date) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('day', isEqualTo: date.day)
        .get();
    return snapshot.docs.map((doc) => Schedule_CRUD.fromDocument(doc)).toList();
  }


  // Update
  //updateSchedule 메서드는 'schedules' 컬렉션에서 일치하는 일정을 찾아 데이터를 업데이트
  static Future<void> updateSchedule(Schedule_CRUD updatedSchedule) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('day', isEqualTo: updatedSchedule.day)
        .where('time', isEqualTo: updatedSchedule.time)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update(updatedSchedule.toMap());
    }
  }


  // Delete
  //eleteSchedule 메서드는 'schedules' 컬렉션에서 일치하는 모든 일정을 삭제
  static Future<void> deleteSchedule(Schedule_CRUD schedule) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('day', isEqualTo: schedule.day)
        .where('time', isEqualTo: schedule.time)
        .where('planedwork', isEqualTo: schedule.planedwork)
        .where('unplanedwork', isEqualTo: schedule.unplanedwork)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  //이 메서드는 새로운 day, time, planedwork, unplanedwork 값을 받아 새로운 Schedule_CRUD 객체를 생성
  // 만약 새로운 값이 제공되지 않으면(null이면), 기존 객체의 값을 사용
  Schedule_CRUD copyWith({
    int? day,
    String? time,
    String? planedwork,
    String? unplanedwork,
  }) {
    return Schedule_CRUD(
      day: day ?? this.day,
      time: time ?? this.time,
      planedwork: planedwork ?? this.planedwork,
      unplanedwork: unplanedwork ?? this.unplanedwork,
    );
  }
}