/**
 * 이벤트 모델
 */
class EventModel {
  final String eventId;         // 이벤트 ID
  final String categoryId;      // 카테고리 ID
  final String userId;          // 사용자 ID
  final DateTime eventDate;     // 이벤트 날짜
  final DateTime eventSttTime;  // 이벤트 시작시간
  final DateTime eventEndTime;  // 이벤트 종료시간
  final String eventTitle;      // 이벤트 제목
  final String eventContent;    // 이벤트 내용
  final String allDayYn;        // 종일 여부
  final String completeYn;      // 완료 여부
  final bool isRecurring;       // 중복 여부

  EventModel({
    required this.eventId,
    required this.categoryId,
    required this.userId,
    required this.eventDate,
    required this.eventSttTime,
    required this.eventEndTime,
    required this.eventTitle,
    required this.eventContent,
    required this.allDayYn,
    required this.completeYn,
    required this.isRecurring,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'categoryId': categoryId,
      'userId': userId,
      'eventDate': eventDate.toIso8601String(),
      'eventSttTime': eventSttTime.toIso8601String(),
      'eventEndTime': eventEndTime.toIso8601String(),
      'eventTitle': eventTitle,
      'eventContent': eventContent,
      'allDayYn': allDayYn,
      'completeYn': completeYn,
      'isRecurring':isRecurring,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['eventId'],
      categoryId: map['categoryId'],
      userId: map['userId'],
      eventDate: DateTime.parse(map['eventDate']),
      eventSttTime: DateTime.parse(map['eventSttTime']),
      eventEndTime: DateTime.parse(map['eventEndTime']),
      eventTitle: map['eventTitle'],
      eventContent: map['eventContent'],
      allDayYn: map['allDayYn'],
      completeYn: map['completeYn'],
      isRecurring: map['isRecurring'],

    );
  }

}

