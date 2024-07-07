import 'package:dart_openai/dart_openai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import 'calendar_service.dart';

class ChatService {



  final CalendarService _calendarService = CalendarService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  ChatService() {
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
  }

  Future<String> createModel(String sendMessage) async {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "너는 아주 훌륭한 개인 비서야." +
                "사용자가 일정 추가,삭제 수정,조회를 요청하면 아래의 형식을 보여주세요" +
                "일정 추가 요청문 : 일정 이름: ..., 날짜: 0000-00-00, 시작 시간: 00;00, 종료 시간: 00;00, 세부사항: ... , 일정 추가 해줘" +
                " 일정 수정 요청문 : 일정 제목: ..., 새 제목: ..., 새 날짜: 0000-00-00, 새 시작 시간: 00;00, 새 종료 시간: 00;00, 새 세부사항: ... , 일정 수정 해줘" +
                "일정 조회 요청문 : 일정 조회 해줘" +
                "일정 삭제 요청문 : 일정 제목: ..., 삭제 해줘" +
                "")
      ],
      role: OpenAIChatMessageRole.system,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          sendMessage,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];

    OpenAIChatCompletionModel chatCompletion =
    await OpenAI.instance.chat.create(
      model: 'gpt-4',
      messages: requestMessages,
      maxTokens: 250,
    );

    String aiResponse =
    chatCompletion.choices.first.message.content![0].text.toString();

    if (sendMessage.toLowerCase().contains("회고 요약") ||
        sendMessage.toLowerCase().contains("회고 요약해줘")) {
      aiResponse = await summarizeRetrospective();
    } else if (sendMessage.toLowerCase().contains("일정 분석") ||
        sendMessage.toLowerCase().contains("일정 개선점") ||
        sendMessage.toLowerCase().contains("일정 제안")) {
      aiResponse = await analyzeAndSuggestSchedule();
      // Firestore에서 일정 조회
    } else if (sendMessage.toString().endsWith("조회해줘") ||
        sendMessage.toString().endsWith("조회 해줘")) {
      List<EventModel> events = await _calendarService.getEvents();
      if (events.isEmpty) {
        aiResponse = "일정이 없습니다";
      } else {
        String eventDetails = events.map((event) {
          return "${event.eventTitle} 일정이 ${DateFormat('yyyy-MM-dd').format(
              event.eventDate ?? DateTime.now())} ${DateFormat('HH:mm').format(
              event.eventSttTime ?? DateTime.now())}시에 있습니다. 세부사항 내용은 ${event
              .eventContent} 입니다";
        }).join("\n");

        aiResponse = "며칠 안 남은 일정 목록입니다:\n$eventDetails";
      }
    } else if (sendMessage.toString().endsWith("추가해줘") ||
        sendMessage.toString().endsWith("추가 해줘")) {
      aiResponse = await _addEvent(sendMessage);
    } else if (sendMessage.toString().endsWith("삭제해줘") ||
        sendMessage.toString().endsWith("삭제 해줘")) {
      aiResponse = await _deleteEvent(sendMessage);
    } else if (sendMessage.toString().endsWith("수정해줘") ||
        sendMessage.toString().endsWith("수정 해줘")) {
      aiResponse = await _updateEvent(sendMessage);
    }



    return aiResponse;
  }

  Future<List<String>> getRetrospectives(String formattedYesterday) async {
    final snapshot = await _firestore
        .collection('review')
        .where('reviewTitle', isEqualTo: '오늘의 일기')
        .get();
    return snapshot.docs.map((doc) => doc['reviewContent'] as String).toList();
  }

  Future<String> summarizeRetrospective() async {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final formattedYesterday = DateFormat('yyyyMMdd').format(yesterday);

    final retrospectives = await getRetrospectives(formattedYesterday);
    if (retrospectives.isEmpty) {
      return "$formattedYesterday의 회고 내용이 없습니다.";
    }

    final combinedRetrospective = retrospectives.join("\n\n");

    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "다음 회고 내용을 요약해주세요. 회고 요약은 100자 이하로 작성 해주세요. 요약을 보여주기 전에 요약할 회고 내용을 먼저 보여주고 요약해서 보여주세요"
        )
      ],
      role: OpenAIChatMessageRole.system,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          combinedRetrospective,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];

    OpenAIChatCompletionModel chatCompletion =
    await OpenAI.instance.chat.create(
      model: 'gpt-4',
      messages: requestMessages,
      maxTokens: 800,
    );

    return chatCompletion.choices.first.message.content![0].text.toString();
  }

  Future<String> analyzeAndSuggestSchedule() async {
    final CalendarService _calendarService = CalendarService();
    List<EventModel> events = await _calendarService.getEvents();
    Map<String, String> categoryNames = await getCategoryNames();

    if (events.isEmpty) {
      return "현재 일정이 없습니다. 일정을 추가하시면 분석해 드리겠습니다.";
    }

    // 현재 날짜 이후의 이벤트만 필터링
    final now = DateTime.now();
    events = events.where((event) => event.eventDate != null && event.eventDate!.isAfter(now)).toList();

    if (events.isEmpty) {
      return "앞으로 예정된 일정이 없습니다. 새로운 일정을 추가해보는 것은 어떨까요?";
    }

    // 일정 분석 및 제안 생성
    String analysis = "일정 분석 및 제안:\n\n";

    // 일정 간 간격 확인
    events.sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
    for (int i = 0; i < events.length - 1; i++) {
      final gap = events[i + 1].eventDate!.difference(events[i].eventDate!).inDays;
      if (gap > 7) {
        analysis += "- ${events[i].eventTitle}와 ${events[i + 1].eventTitle} 사이에 ${gap}일의 간격이 있습니다. "
            "이 기간 동안 추가 활동을 계획해보는 것은 어떨까요?\n\n";
      }
    }

    // 긴 일정 확인
    for (var event in events) {
      if (event.eventEndTime != null) {
        final duration = event.eventEndTime!.difference(event.eventSttTime!).inHours;
        if (duration > 4) {
          analysis += "- ${event.eventTitle} 일정이 ${duration}시간으로 다소 깁니다. "
              "중간에 휴식을 추가하거나 나눠서 진행하는 것을 고려해보세요.\n\n";
        }
      }
    }

    // 카테고리 균형 확인
    Map<String, int> categoryCount = {};
    for (var event in events) {
      categoryCount[event.categoryId] = (categoryCount[event.categoryId] ?? 0) + 1;
    }

    if (categoryCount.isNotEmpty) {
      final maxCategory = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final minCategory = categoryCount.entries.reduce((a, b) => a.value < b.value ? a : b).key;

      if (categoryCount[maxCategory]! > categoryCount[minCategory]! * 2) {
        final maxCategoryName = categoryNames[maxCategory] ?? maxCategory;
        analysis += "- ${maxCategoryName} 카테고리의 일정이 다른 카테고리에 비해 많습니다. "
            "다른 영역의 활동도 균형있게 추가해보는 것은 어떨까요?\n\n";
      }
    }


    // 전반적인 제안
    analysis += "전반적으로, 일정의 균형과 효율성을 높이기 위해 다음을 고려해보세요:\n"
        "1. 긴 일정은 작은 단위로 나누어 관리하기\n"
        "2. 일정 사이의 큰 간격에 새로운 활동 추가하기\n"
        "3. 다양한 카테고리의 활동을 균형있게 배치하기\n";

    return analysis;
  }
  Future<Map<String, String>> getCategoryNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    return Map.fromEntries(
        snapshot.docs.map((doc) => MapEntry(doc.id, doc['categoryName'] as String))
    );
  }



  Future<String> _addEvent(String sendMessage) async {
    try {
      // 예시 명령어: "add event title: Meeting, date: 2024-05-22, start: 14:00, end: 15:00, content: Team meeting"
      final regExp = RegExp(
        r"일정 이름:\s*(.+?),\s*날짜:\s*(.+?),\s*시작 시간:\s*(.+?),\s*종료 시간:\s*(.+?),\s*세부사항:\s*(.+),",
        caseSensitive: false,
      );

      final match = regExp.firstMatch(sendMessage);
      if (match != null) {
        final title = match.group(1)?.trim();
        final date = DateTime.parse(match.group(2)?.trim() ?? '');
        final startTime = TimeOfDay(
          hour: int.parse(match.group(3)?.split(':')[0] ?? '0'),
          minute: int.parse(match.group(3)?.split(':')[1] ?? '0'),
        );
        final endTime = TimeOfDay(
          hour: int.parse(match.group(4)?.split(':')[0] ?? '0'),
          minute: int.parse(match.group(4)?.split(':')[1] ?? '0'),
        );
        final content = match.group(5)?.trim();

        if (title != null &&
            date != null &&
            startTime != null &&
            endTime != null &&
            content != null) {
          final newEvent = EventModel(
            eventTitle: title,
            eventDate: date,
            eventContent: content,
            eventId: '',
            categoryId: '',
            userId: '',
            eventSttTime: DateTime(date.year, date.month, date.day,
                startTime.hour, startTime.minute),
            eventEndTime: DateTime(
                date.year, date.month, date.day, endTime.hour, endTime.minute),
            isAllDay: false,
            completeYn: 'N',
            isRecurring: false,
          );

          final eventRef =
              await _firestore.collection('events').add(newEvent.toMap());
          final eventId = eventRef.id;
          await eventRef.update({'eventId': eventId});

          // 시간 형식 변환
          String formatTimeOfDay(TimeOfDay time) {
            final now = DateTime.now();
            final dt =
                DateTime(now.year, now.month, now.day, time.hour, time.minute);
            final format = DateFormat.Hm(); // or add your favorite format
            return format.format(dt);
          }

          return "일정 추가되었습니다 : $title 일정을 ${DateFormat('yyyy-MM-dd').format(date)} 일 ${formatTimeOfDay(startTime)}시 부터 ${formatTimeOfDay(endTime)}시 사이에 저장했습니다 ";
        } else {
          return "정확한 정보를 입력해주세요";
        }
      } else {
        return "이벤트 정보 확인에 실패했습니다. 이 양식으로 추가해주세요: 일정 이름: ..., 날짜: 0000-00-00, 시작 시간: 00;00, 종료 시간: 00;00, 세부사항: ... , 일정 추가 해줘";
      }
    } catch (e) {
      return "일정 추가에 실패했습니다: ${e.toString()}";
    }
  }

  Future<String> _deleteEvent(String sendMessage) async {
    try {
      final regExp = RegExp(
        r"일정 제목:\s*(.+?),\s*삭제",
        caseSensitive: false,
      );

      final match = regExp.firstMatch(sendMessage);
      if (match != null) {
        final title = match.group(1)?.trim();

        if (title != null) {
          final events = await _calendarService.getEvents();
          final index = events.indexWhere((e) => e.eventTitle == title);

          if (index != -1) {
            final event = events[index];
            await _calendarService.deleteEvent(event.eventId);
            return "일정이 삭제되었습니다: $title";
          } else {
            return "일정을 찾을 수 없습니다: $title";
          }
        } else {
          return "정확한 정보를 입력해주세요";
        }
      } else {
        return "이벤트 정보 확인에 실패했습니다. 이 양식으로 삭제해주세요: 일정 제목: ..., 삭제 해줘";
      }
    } catch (e) {
      return "일정 삭제에 실패했습니다: ${e.toString()}";
    }
  }

  Future<String> _updateEvent(String sendMessage) async {
    try {
      final regExp = RegExp(
        r"일정 제목:\s*(.+?),\s*새 제목:\s*(.+?),\s*새 날짜:\s*(.+?),\s*새 시작 시간:\s*(.+?),\s*새 종료 시간:\s*(.+?),\s*새 세부사항:\s*(.+),",
        caseSensitive: false,
      );

      final match = regExp.firstMatch(sendMessage);
      if (match != null) {
        final oldTitle = match.group(1)?.trim();
        final newTitle = match.group(2)?.trim();
        final newDate = DateTime.parse(match.group(3)?.trim() ?? '');
        final newStartTime = TimeOfDay(
          hour: int.parse(match.group(4)?.split(':')[0] ?? '0'),
          minute: int.parse(match.group(4)?.split(':')[1] ?? '0'),
        );
        final newEndTime = TimeOfDay(
          hour: int.parse(match.group(5)?.split(':')[0] ?? '0'),
          minute: int.parse(match.group(5)?.split(':')[1] ?? '0'),
        );
        final newContent = match.group(6)?.trim();

        if (oldTitle != null &&
            newTitle != null &&
            newDate != null &&
            newStartTime != null &&
            newEndTime != null &&
            newContent != null) {
          final events = await _calendarService.getEvents();
          final index = events.indexWhere((e) => e.eventTitle == oldTitle);

          if (index != -1) {
            final event = events[index];
            final updatedEvent = EventModel(
              eventTitle: newTitle,
              eventDate: newDate,
              eventContent: newContent,
              eventId: event.eventId,
              categoryId: event.categoryId,
              userId: event.userId,
              eventSttTime: DateTime(newDate.year, newDate.month, newDate.day,
                  newStartTime.hour, newStartTime.minute),
              eventEndTime: DateTime(newDate.year, newDate.month, newDate.day,
                  newEndTime.hour, newEndTime.minute),
              isAllDay: event.isAllDay,
              completeYn: event.completeYn,
              isRecurring: event.isRecurring,
            );

            await _calendarService.updateEvent(event.eventId, updatedEvent);
            return "일정이 수정되었습니다: $oldTitle -> $newTitle";
          } else {
            return "일정을 찾을 수 없습니다: $oldTitle";
          }
        } else {
          return "정확한 정보를 입력해주세요";
        }
      } else {
        return "이벤트 정보 확인에 실패했습니다. 이 양식으로 수정해주세요: 일정 제목: ..., 새 제목: ..., 새 날짜: 0000-00-00, 새 시작 시간: 00;00, 새 종료 시간: 00;00, 새 세부사항: ... , 일정 수정 해줘";
      }
    } catch (e) {
      return "일정 수정에 실패했습니다: ${e.toString()}";
    }
  }
}

