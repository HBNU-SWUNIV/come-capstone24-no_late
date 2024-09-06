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
  final bool isAllDay; // 종일 여부
  final bool? isRecurring; // 중복 여부
  final String? completedYn;
  final bool showOnCalendar; // 추가: 캘린더에 표시 여부를 나타내는 필드
  final String? categoryColor;
  final String originalEventId;

  EventModel({
    required this.eventId,
    required this.categoryId,
    required this.userId,
    this.eventDate,
    this.eventSttTime,
    this.eventEndTime,
    required this.eventTitle,
    this.eventContent,
    this.isAllDay = false,
    this.isRecurring,
    this.completedYn = 'N',
    this.showOnCalendar = true, // 추가: 기본값은 true로 설정
    this.categoryColor,
    required this.originalEventId,
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
      'isAllDay': isAllDay,
      'isRecurring': isRecurring,
      'showOnCalendar': showOnCalendar, // 추가: showOnCalendar 값을 맵에 추가
      'completedYn': completedYn,
      'originalEventId': originalEventId,

    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    final eventModel = EventModel(
      eventId: map['eventId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      userId: map['userId'] ?? '',
      eventDate:
          map['eventDate'] != null ? DateTime.parse(map['eventDate']) : null,
      eventSttTime: map['eventSttTime'] != null
          ? DateTime.parse(map['eventSttTime'])
          : null,
      eventEndTime: map['eventEndTime'] != null
          ? DateTime.parse(map['eventEndTime'])
          : null,
      eventTitle: map['eventTitle'] ?? '',
      eventContent: map['eventContent'] ?? '',
      isAllDay: map['isAllDay'] ?? false,
      isRecurring: map['isRecurring'],
      showOnCalendar: map['showOnCalendar'] ?? true,
      // 추가: showOnCalendar 값을 가져옴 (기본값은 true)
      categoryColor: map['categoryColor'],
      completedYn: map['completedYn'] ?? 'N',
      originalEventId: map['originalEventId'] ?? map['eventId'],
    );
    print(
        'Created EventModel: ${eventModel.eventTitle}, CategoryID: ${eventModel.categoryId}, CategoryColor: ${eventModel.categoryColor}');
    return eventModel;
    return eventModel;
  }

  EventModel copyWith({
    String? eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventContent,
    String? categoryId,
    String? userId,
    DateTime? eventSttTime,
    DateTime? eventEndTime,
    bool? isAllDay,
    String? completedYn,
    bool? isRecurring,
    bool? showOnCalendar,
    String? categoryColor,
    String? originalEventId,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventContent: eventContent ?? this.eventContent,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      eventSttTime: eventSttTime ?? this.eventSttTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      isAllDay: isAllDay ?? this.isAllDay,
      completedYn: completedYn ?? this.completedYn,
      isRecurring: isRecurring ?? this.isRecurring,
      showOnCalendar: showOnCalendar ?? this.showOnCalendar,
      categoryColor: categoryColor ?? this.categoryColor,
      originalEventId: originalEventId ?? this.originalEventId,
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
