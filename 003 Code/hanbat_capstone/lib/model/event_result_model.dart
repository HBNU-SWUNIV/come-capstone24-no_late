class EventResultModel {
  final String eventRetId;         // 이벤트 결과 ID
  final String categoryId;         // 카테고리 ID
  final String userId;             // 사용자 ID
  final DateTime eventRetDate;     // 이벤트 결과 날짜
  final DateTime eventRetSttTime;  // 이벤트 결과 시작시간
  final DateTime eventRetEndTime;  // 이벤트 결과 종료시간
  final String eventRetTitle;      // 이벤트 결과 제목
  final String eventRetContent;    // 이벤트 결과 내용

  EventResultModel({
    required this.eventRetId,
    required this.categoryId,
    required this.userId,
    required this.eventRetDate,
    required this.eventRetSttTime,
    required this.eventRetEndTime,
    required this.eventRetTitle,
    required this.eventRetContent,
  });
}