class EventResultModel {
  final String eventResultId; // 이벤트 결과 ID
  final String eventId; // 이벤트 ID
  final String categoryId; // 카테고리 ID
  final String userId; // 사용자 ID
  final DateTime eventResultDate; // 이벤트 결과 날짜
  final DateTime eventResultSttTime; // 이벤트 결과 시작시간
  final DateTime eventResultEndTime; // 이벤트 결과 종료시간
  final String eventResultTitle; // 이벤트 결과 제목
  final String eventResultContent; // 이벤트 결과 내용
  final String completeYn; // 완료 여부

  EventResultModel({
    required this.eventResultId,
    required this.eventId,
    required this.categoryId,
    required this.userId,
    required this.eventResultDate,
    required this.eventResultSttTime,
    required this.eventResultEndTime,
    required this.eventResultTitle,
    required this.eventResultContent,
    required this.completeYn,
  });

  // toMap, fromMap 메서드 추가
  Map<String, dynamic> toMap() {
    return {
      'eventResultId': eventResultId,
      'eventId': eventId,
      'categoryId': categoryId,
      'userId': userId,
      'eventResultDate': eventResultDate,
      'eventResultSttTime': eventResultSttTime,
      'eventResultEndTime': eventResultEndTime,
      'eventResultTitle': eventResultTitle,
      'eventResultContent': eventResultContent,
      'completeYn': completeYn,
    };
  }

  factory EventResultModel.fromMap(Map<String, dynamic> map) {
    return EventResultModel(
      eventResultId: map['eventResultId'],
      eventId: map['eventId'],
      categoryId: map['categoryId'],
      userId: map['userId'],
      eventResultDate: map['eventResultDate'].toDate(),
      eventResultSttTime: map['eventResultSttTime'].toDate(),
      eventResultEndTime: map['eventResultEndTime'].toDate(),
      eventResultTitle: map['eventResultTitle'],
      eventResultContent: map['eventResultContent'],
      completeYn: map['completeYn'],
    );
  }

  EventResultModel copyWith({
    String? eventResultId,
    String? eventId,
    String? categoryId,
    String? userId,
    DateTime? eventResultDate,
    DateTime? eventResultSttTime,
    DateTime? eventResultEndTime,
    String? eventResultTitle,
    String? eventResultContent,
    String? completeYn,
  }) {
    return EventResultModel(
      eventResultId: eventResultId ?? this.eventResultId,
      eventId: eventId ?? this.eventId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      eventResultDate: eventResultDate ?? this.eventResultDate,
      eventResultSttTime: eventResultSttTime ?? this.eventResultSttTime,
      eventResultEndTime: eventResultEndTime ?? this.eventResultEndTime,
      eventResultTitle: eventResultTitle ?? this.eventResultTitle,
      eventResultContent: eventResultContent ?? this.eventResultContent,
      completeYn: completeYn ?? this.completeYn,
    );
  }
}