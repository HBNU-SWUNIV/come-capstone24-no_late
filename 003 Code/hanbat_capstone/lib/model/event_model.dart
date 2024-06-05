import 'package:cloud_firestore/cloud_firestore.dart';


class EventModel {
  final String eventId; // 이벤트 ID
  final String categoryId; // 카테고리 ID
  final String userId; // 사용자 ID
  final DateTime? eventDate; // 이벤트 날짜
  final DateTime? eventSttTime; // 이벤트 시작시간
  final DateTime? eventEndTime; // 이벤트 종료시간
  final String eventTitle; // 이벤트 제목
  final String? eventContent; // 이벤트 내용
  final String allDayYn; // 종일 여부
  final bool? isRecurring; // 중복 여부
  final String? completeYn;

  EventModel({
    required this.eventId,
    required this.categoryId,
    required this.userId,
    this.eventDate,
    this.eventSttTime,
    this.eventEndTime,
    required this.eventTitle,
    this.eventContent,
    required this.allDayYn,
    this.isRecurring,
    this.completeYn,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'categoryId': categoryId,
      'userId': userId,
      'eventDate': eventDate?.toIso8601String(),
      'eventSttTime': eventSttTime?.toIso8601String(),
      'eventEndTime': eventEndTime?.toIso8601String(),
      'eventTitle': eventTitle,
      'eventContent': eventContent,
      'allDayYn': allDayYn,
      'isRecurring':isRecurring,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['eventId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      userId: map['userId'] ?? '',
      eventDate:map['eventDate'] != null
          ? DateTime.parse(map['eventDate'])
          : null,
      eventSttTime:  map['eventSttTime'] != null
          ? DateTime.parse(map['eventSttTime'])
          : null,
      eventEndTime: map['eventEndTime'] != null
          ? DateTime.parse(map['eventEndTime'])
          : null,
      eventTitle: map['eventTitle'] ?? '',
      eventContent: map['eventContent'] ?? '',
      allDayYn: map['allDayYn'] ?? '',
      isRecurring: map['isRecurring'],
    );
  }
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
