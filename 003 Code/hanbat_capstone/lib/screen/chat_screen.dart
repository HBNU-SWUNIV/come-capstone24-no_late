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
        eventDate: (_toDate(data['eventDate'])),
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
}

class ChatService {

  final CalendarService _calendarService = CalendarService();

  ChatService() {
    // OpenAI.apiKey = OPENAI_API_KEY;// 실제 API 키를 입력하세요.
    OpenAI.requestsTimeOut = const Duration(seconds: 60); // 시간 제한 늘림
  }

  Future<String> createModel(String sendMessage) async {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You're my personal assistant",
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
    if (sendMessage.toLowerCase().contains("what are my events")) {
      List<EventModel> events = await _calendarService.getEvents();
      if (events.isEmpty) {
        aiResponse = "I don't have access to your personal calendar or events. You may want to check your calendar app or planner for your upcoming events. Let me know if you need help with anything else.";
      } else {
        String eventDetails = events.map((event) {
          return "${event.eventTitle} on ${DateFormat('yyyy-MM-dd').format(event.eventDate ?? DateTime.now())} from ${DateFormat('HH:mm').format(event.eventSttTime ?? DateTime.now())}: ${event.eventContent}";
        }).join("\n");

        aiResponse = "Here are your upcoming events:\n$eventDetails";
      }

    }

    return aiResponse;
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
    return Scaffold(
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
    );
  }
}

class MessageModel {
  final String text;
  final bool isUserMessage;

  MessageModel({required this.text, required this.isUserMessage});
}