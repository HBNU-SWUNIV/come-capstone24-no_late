import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import 'calendar_service.dart';

class AdvancedChatService {
  final CalendarService _calendarService = CalendarService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdvancedChatService() {
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
  }

  Future<String> processUserMessage(String userMessage) async {
    final now = DateTime.now();
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            '''
          You are an assistant that helps manage schedules. Today's date is ${DateFormat('yyyy-MM-dd').format(now)}.
          Analyze the following sentence, extract scheduling details such as event title, date, start time, and end time. If any information is missing, return it as null.


          - Event title (e.g., "Meeting", "Lunch")
          - Event date in the format YYYY-MM-DD (e.g., "2024-10-04")
          - Start time in the format HH:MM (e.g., "09:00")
          - End time in the format HH:MM (e.g., "10:00"), if applicable
          - Is the event all-day? (True/False)
          Return the result in this JSON format:
          {
            "action": "add",
            "title": "<event title>",
            "date": "<YYYY-MM-DD>",
            "startTime": "<HH:MM or null>",
            "endTime": "<HH:MM or null>",
            "isAllDay": <True/False>
          }
          Example:
          Input: "내일 오전 9시부터 오후 5시까지 회의 있어."
          Output:
          {
            "action": "add",
            "title": "회의",
            "date": "2024-10-04",
            "startTime": "2024-10-04 09:00",
            "endTime": "2024-10-04 17:00",
            "isAllDay": false
          }
          For viewing events, use: {"action": "view"}
          For updating events, use: {"action": "update", "oldTitle": "<old title>", ...}
          For deleting events, use: {"action": "delete", "title": "<title to delete>"}
          For general chat, use: {"action": "chat", "response": "<general response>"}
          Always ensure your response is a valid JSON string and nothing else.
          '''
        )
      ],
      role: OpenAIChatMessageRole.system,
    );

    final userMessageModel = OpenAIChatCompletionChoiceMessageModel(
      content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage)],
      role: OpenAIChatMessageRole.user,
    );

    final chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-4',
      messages: [systemMessage, userMessageModel],
      maxTokens: 300,
    );

    final aiResponse = chatCompletion.choices.first.message.content![0].text;
    return await _processAIResponse(aiResponse!, userMessage);
  }

  Future<String> _processAIResponse(String aiResponse, String originalMessage) async {
    try {
      // 응답에서 JSON 부분만 추출 시도
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(aiResponse);
      Map<String, dynamic> responseJson;

      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0);
        responseJson = json.decode(jsonString!);
      } else {
        // JSON을 찾지 못한 경우, 전체 응답을 일반 채팅으로 처리
        responseJson = {
          "action": "chat",
          "response": aiResponse
        };
      }

      switch (responseJson['action']) {
        case 'add':
          return await _addEvent(responseJson);
        case 'view':
          return await _getEvents();
        case 'update':
          return await _updateEvent(responseJson);
        case 'delete':
          return await _deleteEvent(responseJson);
        case 'chat':
          return responseJson['response'] ?? "응답을 생성하지 못했습니다.";
        default:
        // 작업을 식별할 수 없는 경우, 원본 메시지를 기반으로 응답 생성
          return "죄송합니다. 요청을 완전히 이해하지 못했습니다. '$originalMessage'에 대해 더 자세히 설명해 주시겠어요?";
      }
    } on FormatException catch (e) {
      print("Format Error: $e");
      print("Original AI Response: $aiResponse");
      return "응답을 처리하는 중 오류가 발생했습니다. 다시 한 번 말씀해 주시겠어요?";
    } catch (e) {
      print("Error: $e");
      print("Original AI Response: $aiResponse");
      return "오류가 발생했습니다. 다시 시도해 주세요.";
    }
  }

  Future<String> _addEvent(Map<String, dynamic> eventData) async {
    try {
      final now = DateTime.now();
      final eventDate = _parseDate(eventData['date']) ?? now;

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return "로그인이 필요합니다. 먼저 로그인해 주세요.";
      }

      final startTime = _parseTimeString(eventData['startTime'],eventDate);
      final endTime = _parseTimeString(eventData['endTime'],eventDate);

      // 시작 시간과 종료 시간에 이벤트 날짜를 적용
      final eventStartTime = startTime != null
          ? DateTime(eventDate.year, eventDate.month, eventDate.day, startTime.hour, startTime.minute)
          : null;
      final eventEndTime = endTime != null
          ? DateTime(eventDate.year, eventDate.month, eventDate.day, endTime.hour, endTime.minute)
          : null;

      final newEvent = EventModel(
        eventTitle: eventData['title'] ?? "Untitled Event",
        eventDate: eventDate,
        eventContent: eventData['content'] ?? '',
        eventId: '',
        categoryId: '',
        userId: currentUser.uid,
        eventSttTime: eventStartTime,
        eventEndTime: eventEndTime,
        isAllDay: eventData['isAllDay'] ?? false,
        completedYn: 'N',
        isRecurring: false,
        originalEventId: FirebaseFirestore.instance.collection('events').doc().id,
      );

      final eventMap = newEvent.toMap();
      final eventRef = await _firestore.collection('events').add(eventMap);
      final eventId = eventRef.id;
      await eventRef.update({'eventId': eventId});

      return "${eventData['title'] ?? 'Untitled Event'} 일정이 ${DateFormat('yyyy-MM-dd').format(eventDate)}에 추가되었습니다. "
          "시작 시간: ${_formatTime(newEvent.eventSttTime)}, "
          "종료 시간: ${_formatTime(newEvent.eventEndTime)}";
    } catch (e) {
      print("Add Event Error: $e");
      return "일정 추가 중 오류가 발생했습니다. 다시 시도해 주세요.";
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print("Date parsing error: $e");
      return null;
    }
  }

  DateTime? _parseTimeString(String? timeString, DateTime baseDate) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final timeParts = timeString.split(':');
      return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1])
      );
    } catch (e) {
      print("Time parsing error: $e");
      return null;
    }
  }
  String _formatTime(DateTime? time) {
    if (time == null) return '지정되지 않음';
    return DateFormat('HH:mm').format(time);
  }

  Future<String> _getEvents() async {
    try {
      List<EventModel> events = await _calendarService.getEvents();
      if (events.isEmpty) {
        return "현재 등록된 일정이 없습니다.";
      } else {
        return events.map((event) =>
        "${event.eventTitle}: ${DateFormat('yyyy-MM-dd').format(event.eventDate ?? DateTime.now())} "
            "${DateFormat('HH:mm').format(event.eventSttTime ?? DateTime.now())} - "
            "${DateFormat('HH:mm').format(event.eventEndTime ?? DateTime.now())}\n"
            "세부사항: ${event.eventContent}"
        ).join("\n\n");
      }
    } catch (e) {
      return "일정 조회 중 오류가 발생했습니다: ${e.toString()}";
    }
  }

  Future<String> _updateEvent(Map<String, dynamic> eventData) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return "로그인이 필요합니다. 먼저 로그인해 주세요.";
      }

      final newDate = _parseDate(eventData['newDate']);

      // 모든 사용자 일정을 가져옵니다
      final allEvents = await _getAllUserEvents(currentUser.uid);

      final matchingEvents = allEvents.where(
              (e) => e.eventTitle.toLowerCase().contains(eventData['title'].toLowerCase())
      ).toList();

      if (matchingEvents.isEmpty) {
        return "\"${eventData['title']}\" 제목의 일정을 찾을 수 없습니다.";
      }

      if (matchingEvents.length > 1) {
        final eventDetails = matchingEvents.map((e) =>
        "${e.eventTitle}: ${DateFormat('yyyy-MM-dd').format(e.eventDate ?? DateTime.now())}"
        ).join('\n');
        return "\"${eventData['title']}\"와 일치하는 일정이 여러 개 있습니다:\n$eventDetails\n더 구체적인 제목을 입력해주세요.";
      }

      final eventToUpdate = matchingEvents.first;
      final updateDate = newDate ?? eventToUpdate.eventDate ?? DateTime.now();

      final updatedStartTime = _parseTimeString(eventData['startTime'], updateDate) ?? eventToUpdate.eventSttTime ?? updateDate;
      final updatedEndTime = _parseTimeString(eventData['endTime'], updateDate) ?? eventToUpdate.eventEndTime ?? updateDate.add(Duration(hours: 1));

      final updatedEvent = EventModel(
        eventTitle: eventData['newTitle'] ?? eventToUpdate.eventTitle,
        eventDate: updateDate,
        eventContent: eventData['content'] ?? eventToUpdate.eventContent,
        eventId: eventToUpdate.eventId,
        categoryId: eventToUpdate.categoryId,
        userId: eventToUpdate.userId,
        eventSttTime: updatedStartTime,
        eventEndTime: updatedEndTime,
        isAllDay: eventData['isAllDay'] ?? eventToUpdate.isAllDay,
        completedYn: eventToUpdate.completedYn,
        isRecurring: eventToUpdate.isRecurring,
        originalEventId: eventToUpdate.originalEventId,
      );

      await _calendarService.updateEvent(eventToUpdate.eventId, updatedEvent);

      String updateMessage = "${eventToUpdate.eventTitle} 일정이 성공적으로 업데이트되었습니다.";
      if (newDate != null && !_isSameDay(eventToUpdate.eventDate, newDate)) {
        updateMessage += " 날짜가 ${DateFormat('yyyy-MM-dd').format(eventToUpdate.eventDate ?? DateTime.now())}에서 ${DateFormat('yyyy-MM-dd').format(newDate)}로 변경되었습니다.";
      }
      return updateMessage;
    } catch (e) {
      print("Update Event Error: $e");
      return "일정 수정 중 오류가 발생했습니다: ${e.toString()}";
    }
  }

  Future<List<EventModel>> _getAllUserEvents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching all user events: $e");
      return [];
    }
  }
  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }


  Future<String> _deleteEvent(Map<String, dynamic> eventData) async {
    try {
      final events = await _calendarService.getEvents();
      final eventToDelete = events.firstWhere(
              (e) => e.eventTitle == eventData['title'],
          orElse: () => throw Exception("일정을 찾을 수 없습니다.")
      );

      if (eventToDelete == null) {
        return "${eventData['title']} 일정을 찾을 수 없습니다.";
      }

      await _calendarService.deleteEvent(eventToDelete.eventId);
      return "${eventData['title']} 일정이 삭제되었습니다.";
    } catch (e) {
      return "일정 삭제 중 오류가 발생했습니다: ${e.toString()}";
    }
  }
}
