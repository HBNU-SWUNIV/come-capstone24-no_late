import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:hanbat_capstone/model/event_model.dart';
import 'package:hanbat_capstone/model/event_result_model.dart';
import 'package:intl/intl.dart';

/**
 * 회고관리 Business Service
 */
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReviewService() {
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
  }

  Future<String> summarizeRetrospective(DateTime _currentDay) async {
    // 1. 현재 날짜 가져오기
    final formattedCurDay = DateFormat('yyyyMMdd').format(_currentDay);

    // 2. events와 eventResults 정보 파이어베이스에서 조회하기
    final events = await getEvents(formattedCurDay); // 파이어베이스에서 yyyyMMdd로 events 조회
    final eventResults = await getEventResults(formattedCurDay); // 파이어베이스에서 yyyyMMdd로 eventResults 조회

    // 3. 조회된 events와 eventResults 정보 비교하기
    int matchedCount = 0;
    for (var event in events) {
      var correspondingResult = eventResults.firstWhere(
            (result) => result.eventId == event.eventId && result.eventResultTitle == event.eventTitle,
        orElse: () => EventResultModel(eventResultId: '', eventId: '', categoryId: '', userId: '', eventResultTitle: '', completeYn: 'N', showOnCalendar: false),
      );
      if (correspondingResult != null) {
        matchedCount++;
      }
    }

    // 계획된 이벤트의 수와 실제로 수행된 이벤트의 수를 비교
    int totalEvents = events.length;
    double completionPercentage = totalEvents > 0 ? (matchedCount / totalEvents) * 100 : 0;

    // 4. 비교 내용 결합
    String comparisonSummary;
    if (totalEvents == 0) {
      comparisonSummary = "오늘 계획된 이벤트가 없습니다.";
    } else {
      comparisonSummary = "오늘 계획된 이벤트 중 $completionPercentage%가 성공적으로 수행되었습니다.";
    }

    // 5. 요약 요청 메시지 준비
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "계획된 이벤트 정보가 없다면 계획을 작성할 수 있도록 응원해주세요."
                "계획된 이벤트 중 수행률이 50%를 넘지 못하는 경우, 계획된 이벤트를 잘 수행할 수 있도록 응원해주세요."
                "계획된 이벤트 중 수행률이 100%를 넘는 경우, 칭찬해주세요."
                "요약 정보는 구어체로 작성되어야 하며 최대 5문장을 넘기지 않도록 해주세요."
                "요약 정보는 최대 100자 이내로 작성해주세요."
                "요약 전에 계획 정보를 보여드리겠습니다."
        )
      ],
      role: OpenAIChatMessageRole.system,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          comparisonSummary,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];

    // 6. GPT-4에 요약 요청
    OpenAIChatCompletionModel chatCompletion =
    await OpenAI.instance.chat.create(
      model: 'gpt-4',
      messages: requestMessages,
      maxTokens: 800,
    );

    // 7. 요약된 회고 내용 반환
    return chatCompletion.choices.first.message.content![0].text.toString();
  }

  /**
   * 이벤트정보 조회
   */
  Future<List<EventModel>> getEvents(String _formattedCurDay) async {
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
        isAllDay: data['isAllDay'] is bool ? data['isAllDay'] : false,
        completeYn: data['completeYn'] ?? 'N',
        isRecurring: data['isRecurring'] ?? false,
      );
    }).toList();
    return events;
  }

  /**
   * 이벤트 결과 조회
   */
  Future<List<EventResultModel>> getEventResults(String _formattedCurDay) async {
    QuerySnapshot snapshot = await _firestore.collection('eventResults').get();
    List<EventResultModel> eventsResults = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return EventResultModel(
        eventResultId: data['eventResultId'] ?? '',
        eventId: data['eventId'] ?? '',
        categoryId: data['categoryId'] ?? '',
        userId: data['userId'] ?? '',
        eventResultDate: _toDate(data['eventResultDate']),
        eventResultSttTime: _toDate(data['eventResultSttTime']),
        eventResultEndTime: _toDate(data['eventResultEndTime']),
        eventResultTitle: data['eventResultTitle'] ?? '',
        eventResultContent: data['eventResultContent'] ?? '',
        isAllDay: data['isAllDay'] is bool ? data['isAllDay'] : false, // Ensure it's a bool
        completeYn: data['completeYn'] ?? '',
        showOnCalendar: data['showOnCalendar'] ?? true,
      );
    }).toList();

    return eventsResults;
  }

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
}

