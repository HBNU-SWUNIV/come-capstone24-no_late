import 'package:cloud_firestore/cloud_firestore.dart';

class EventResultModel {
  final String eventResultId;
  final String eventId;
  final String categoryId;
  final String userId;
  final DateTime? eventResultDate;
  final DateTime? eventResultSttTime;
  final DateTime? eventResultEndTime;
  final String eventResultTitle;
  final String? eventResultContent;
  final bool? isAllDay;
  final String completedYn;
  final bool showOnCalendar;

  EventResultModel({
    required this.eventResultId,
    required this.eventId,
    required this.categoryId,
    required this.userId,
    this.eventResultDate,
    this.eventResultSttTime,
    this.eventResultEndTime,
    required this.eventResultTitle,
    this.eventResultContent,
    this.isAllDay = false,
    required this.completedYn,
    this.showOnCalendar = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventResultId': eventResultId,
      'eventId': eventId,
      'categoryId': categoryId,
      'userId': userId,
      'eventResultDate': eventResultDate?.toIso8601String(),
      'eventResultSttTime': eventResultSttTime?.toIso8601String(),
      'eventResultEndTime': eventResultEndTime?.toIso8601String(),
      'eventResultTitle': eventResultTitle,
      'eventResultContent': eventResultContent,
      'isAllDay': isAllDay,
      'completedYn': completedYn,
      'showOnCalendar': showOnCalendar,
    };
  }

  factory EventResultModel.fromMap(Map<String, dynamic> map) {
    return EventResultModel(
      eventResultId: map['eventResultId'] ?? '',
      eventId: map['eventId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      userId: map['userId'] ?? '',
      eventResultDate: map['eventResultDate'] != null
          ? DateTime.parse(map['eventResultDate'])
          : null,
      eventResultSttTime: map['eventResultSttTime'] != null
          ? DateTime.parse(map['eventResultSttTime'])
          : null,
      eventResultEndTime: map['eventResultEndTime'] != null
          ? DateTime.parse(map['eventResultEndTime'])
          : null,
      eventResultTitle: map['eventResultTitle'] ?? '',
      eventResultContent: map['eventResultContent'] ?? '',
      isAllDay: map['isAllDay'] ?? '',
      completedYn: map['completedYn'] ?? '',
      showOnCalendar: map['showOnCalendar'] ?? true,
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
    bool? isAllDay,
    String? completedYn,
    bool? showOnCalendar,
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
      isAllDay: isAllDay ?? this.isAllDay,
      completedYn: completedYn ?? this.completedYn,
      showOnCalendar: showOnCalendar ?? this.showOnCalendar,
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}