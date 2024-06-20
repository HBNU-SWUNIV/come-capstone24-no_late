import 'package:dart_openai/dart_openai.dart';
import 'package:hanbat_capstone/model/event_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return null;
    }
  }

  Future<List<EventModel>> getEvents() async {
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    List<EventModel> events = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return EventModel(
        eventTitle: data['eventTitle'] ?? 'No title',
        eventDate: _toDate(data['eventDate']),
        eventContent: data['eventContent'] ?? 'No content',
        eventId: doc.id,
        categoryId: data['categoryId'] ?? '',
        userId: data['userId'] ?? '',
        eventSttTime: _toDate(data['eventSttTime']),
        eventEndTime: _toDate(data['eventEndTime']),
        allDayYn: data['allDayYn'] ?? 'N',
        completeYn: data['completeYn'] ?? 'N',
        isRecurring: data['isRecurring'] ?? false,
      );
    }).toList();
    return events;
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> updateEvent(String eventId, EventModel updatedEvent) async {
    await _firestore.collection('events').doc(eventId).update(
        updatedEvent.toMap());
  }
}

class ChatService {
  final CalendarService _calendarService = CalendarService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatService() {

    OpenAI.requestsTimeOut = const Duration(seconds: 60); // 시간 제한 늘림
  }

  Future<String> createModel(String sendMessage) async {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "너는 아주 훌륭한 상대방의 개인 비서야."
                + "현대의 사람들은 할일이 많아서 시간 관리에 어려움을 겪고 있는 사람들이 많아"
                + "나는 그런 사람들에게 너라는 도구를 이용해서 사람들에게 도움을 주고 싶어"
        ),
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
      model: 'gpt-3.5-turbo',
      messages: requestMessages,
      maxTokens: 250,
    );

    String aiResponse =
    chatCompletion.choices.first.message.content![0].text.toString();

    // Firestore에서 일정 조회
    if (sendMessage.toString().endsWith("조회해줘") ||
        sendMessage.toString().endsWith("조회 해줘")) {
      List<EventModel> events = await _calendarService.getEvents();
      if (events.isEmpty) {
        aiResponse = "일정이 없습니다";
      } else {
        String eventDetails = events.map((event) {
          return "${event.eventTitle} 일정이 ${DateFormat('yyyy-MM-dd').format(
              event.eventDate ?? DateTime.now())} ${DateFormat('HH:mm')
              .format(
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

        if (title != null && date != null && startTime != null &&
            endTime != null && content != null) {
          final newEvent = EventModel(
            eventTitle: title,
            eventDate: date,
            eventContent: content,
            eventId: '',
            categoryId: '',
            userId: '',
            eventSttTime: DateTime(
                date.year, date.month, date.day, startTime.hour,
                startTime.minute),
            eventEndTime: DateTime(
                date.year, date.month, date.day, endTime.hour, endTime.minute),
            allDayYn: 'N',
            completeYn: 'N',
            isRecurring: false,
          );

          final eventRef = await _firestore.collection('events').add(
              newEvent.toMap());
          final eventId = eventRef.id;
          await eventRef.update({'eventId': eventId});

          // 시간 형식 변환
          String formatTimeOfDay(TimeOfDay time) {
            final now = DateTime.now();
            final dt = DateTime(
                now.year, now.month, now.day, time.hour, time.minute);
            final format = DateFormat.Hm(); // or add your favorite format
            return format.format(dt);
          }

          return "일정 추가되었습니다 : $title 일정을 ${DateFormat('yyyy-MM-dd').format(
              date)} 일 ${formatTimeOfDay(startTime)}시 부터 ${formatTimeOfDay(
              endTime)}시 사이에 저장했습니다 ";
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

        if (oldTitle != null && newTitle != null && newDate != null &&
            newStartTime != null && newEndTime != null && newContent != null) {
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
              eventSttTime: DateTime(
                  newDate.year, newDate.month, newDate.day, newStartTime.hour,
                  newStartTime.minute),
              eventEndTime: DateTime(
                  newDate.year, newDate.month, newDate.day, newEndTime.hour,
                  newEndTime.minute),
              allDayYn: event.allDayYn,
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

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<MessageModel> _messages = [];
  final ChatService _chatService = ChatService();
  String _errorMessage = "";

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    setState(() {
      _messages.add(MessageModel(text: text, isUserMessage: true));
    });
    _controller.clear();

    try {
      final response = await _chatService.createModel(text);
      setState(() {
        _messages.add(MessageModel(text: response, isUserMessage: false));
        _errorMessage = ""; // 에러 메시지 초기화
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ChatGPT App'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: Align(
                      alignment: message.isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.isUserMessage
                              ? Colors.blueAccent
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                              color: message.isUserMessage
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Enter your message'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageModel {
  final String text;
  final bool isUserMessage;

  MessageModel({required this.text, required this.isUserMessage});
}