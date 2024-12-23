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

  /**
   * 일별 요약
   */
  Future<String> summarizeRetrospective(DateTime _currentDay, String userId) async {
    // 1. 현재 날짜 가져오기
    final formattedCurDay = DateFormat('yyyyMMdd').format(_currentDay);

    // 2. events와 eventResults 정보 파이어베이스에서 조회하기
    final events = await getEvents(formattedCurDay, userId, 0); // 파이어베이스에서 yyyyMMdd로 events 조회
    final eventResults = await getEventResults(formattedCurDay, userId, 0); // 파이어베이스에서 yyyyMMdd로 eventResults 조회

    // 3. 조회된 events와 eventResults 정보 비교하기
    int matchedCount = 0;
    for (var event in events) {
      var correspondingResult = eventResults.firstWhere(
            (result) => result.eventId == event.eventId && result.eventResultTitle == event.eventTitle,
        orElse: () => EventResultModel(eventResultId: '', eventId: '', categoryId: '', userId: '', eventResultTitle: '', completedYn: 'N', showOnCalendar: false),
      );
      if (correspondingResult.eventId != null && correspondingResult.eventId != '') {
        matchedCount++;
      }
    }

    // 계획된 이벤트의 수와 실제로 수행된 이벤트의 수를 비교
    int totalEvents = events.length;

    // 4. 비교 내용 결합
    String comparisonSummary;
    if (totalEvents == 0) {
      comparisonSummary = "오늘 계획된 이벤트가 없습니다.";
    } else {
      double completionPercentage = totalEvents > 0 ? (matchedCount / totalEvents) * 100 : 0;
      // 만약 계산이 잘못된 경우 소수점 처리를 강제하거나 반올림을 추가
      completionPercentage = completionPercentage.clamp(0, 100);
      comparisonSummary = "오늘 계획된 이벤트가 있고, 계획된 이벤트 중 $completionPercentage%가 성공적으로 수행되었습니다.";
    }

    // 5. 요약 요청 메시지 준비
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "계획된 이벤트가 없는 경우 계획을 세울 수 있도록 격려해주세요. "
            "계획된 이벤트 중 수행률이 50%미만인 경우, 계획된 이벤트를 잘 수행할 수 있도록 응원해주세요. "
            "계획된 이벤트 중 수행률이 70%이상인 경우, 칭찬과 함께 수행률을 더 높일 수 있도록 응원해주세요. "
            "계획된 이벤트를 100% 수행한 경우, 칭찬해주세요. "
            "요약 정보는 구어체로 작성되어야 하며, 최대 4문장을 넘기지 않도록 해주세요. "
            "요약 정보는 최대 100자 이내로 작성해주세요. "
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
   * 주별 요약
   */
  Future<String> summarizeRetrospectiveWeek(DateTime _currentDay, String userId) async {
    // 1. 현재 날짜 가져오기
    final formattedCurDay = DateFormat('yyyyMMdd').format(_currentDay);

    // 2. events와 eventResults 정보 파이어베이스에서 조회하기
    final events = await getEvents(formattedCurDay, userId, 1); // 파이어베이스에서 yyyyMMdd로 events 조회
    final eventResults = await getEventResults(formattedCurDay, userId, 1); // 파이어베이스에서 yyyyMMdd로 eventResults 조회

    // 3-0. 완료 및 미완료 상태 설정
    Map<String, String> eventStatus = {};

    for (var event in events) {
      eventStatus[event.eventId] = event.completedYn ?? 'N';
    }

    for (var result in eventResults) {
      eventStatus[result.eventId] = result.completedYn ?? 'N';
    }

    // 3. 이벤트와 이벤트 결과 비교하기
    List<String> completedEvents = [];
    List<String> pendingEvents = [];

    for (var event in events) {
      /*
      var correspondingResult = eventResults.firstWhere(
            (result) => result.eventId == event.eventId && result.eventResultTitle == event.eventTitle,
        orElse: () => EventResultModel(eventResultId: '', eventId: '', categoryId: '', userId: '', eventResultTitle: '', completedYn: 'N', showOnCalendar: false),
      );

      if (correspondingResult != null && correspondingResult.completedYn == 'Y') {
      */
      if (eventStatus[event.eventId] == 'Y'){
        completedEvents.add(event.eventTitle);
      } else {
        pendingEvents.add(event.eventTitle);
      }
    }

    // 4. 요약 내용 구성
    String comparisonSummary;
    if (events.isEmpty) {
      comparisonSummary = "이번 주에는 계획된 이벤트가 없습니다.";
    } else {
      comparisonSummary = "이번 주 계획된 이벤트 목록입니다:\n"
          "- 완료된 이벤트: ${completedEvents.isNotEmpty ? completedEvents.join(', ') : '없음'}\n"
          "- 미완료 이벤트: ${pendingEvents.isNotEmpty ? pendingEvents.join(', ') : '없음'}";
    }

    // 5. 요약 요청 메시지 준비
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "이번 주에 계획된 이벤트 중 완료된 이벤트와 미완료된 이벤트에 대한 요약 정보를 드릴게요. "
                "계획된 이벤트가 없다면 계획을 세우고 실천할수있도록 격려해주세요."
                "계획된 이벤트를 모두 완료했다면 칭찬해주고, 미완료된 이벤트가 남아있는경우 어떤 이벤트가 남아있는지 알려주세요."
                "요약 정보는 구어체로 작성되어야 하며, 최대 4문장을 넘기지 않도록 해주세요. "
                "요약 정보는 최대 100자 이내로 작성해주세요."
        ),
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
   * 월별 요약
   */
  Future<String> summarizeRetrospectiveMonth(DateTime _currentDay, String userId) async {
    // 1. 현재 날짜 가져오기
    final formattedCurDay = DateFormat('yyyyMMdd').format(_currentDay);

    // 2. events와 eventResults 정보 파이어베이스에서 조회하기
    final events = await getEvents(formattedCurDay, userId, 2); // 파이어베이스에서 yyyyMMdd로 events 조회
    final eventResults = await getEventResults(formattedCurDay, userId, 3); // 파이어베이스에서 yyyyMMdd로 eventResults 조회

    // 3-0. 완료 및 미완료 상태 설정
    Map<String, String> eventStatus = {};

    for (var event in events) {
      eventStatus[event.eventId] = event.completedYn ?? 'N';
    }

    for (var result in eventResults) {
      eventStatus[result.eventId] = result.completedYn ?? 'N';
    }

    // 3. 이벤트와 이벤트 결과 비교하기
    List<String> completedEvents = [];
    List<String> pendingEvents = [];

    for (var event in events) {
      /*
      var correspondingResult = eventResults.firstWhere(
            (result) => result.eventId == event.eventId && result.eventResultTitle == event.eventTitle,
        orElse: () => EventResultModel(eventResultId: '', eventId: '', categoryId: '', userId: '', eventResultTitle: '', completedYn: 'N', showOnCalendar: false),
      );

      if (correspondingResult != null && correspondingResult.completedYn == 'Y') {
       */
      if (eventStatus[event.eventId] == 'Y'){
        completedEvents.add(event.eventTitle);
      } else {
        pendingEvents.add(event.eventTitle);
      }
    }

    // 4. 요약 내용 구성
    String comparisonSummary;
    if (events.isEmpty) {
      comparisonSummary = "이번 달에는 계획된 이벤트가 없습니다.";
    } else {
      comparisonSummary = "이번 달에 계획하여 완료된 이벤트와 미완료된 이벤트 목록입니다:\n"
          "- 완료된 이벤트: ${completedEvents.isNotEmpty ? completedEvents.join(', ') : '없음'}\n"
          "- 미완료 이벤트: ${pendingEvents.isNotEmpty ? pendingEvents.join(', ') : '없음'}";
    }

    print(comparisonSummary);

    // 5. 요약 요청 메시지 준비
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "이번 달에 계획된 이벤트 중 완료된 이벤트와 미완료된 이벤트에 대한 요약 정보를 드릴게요. "
                "계획된 이벤트가 없다면 계획을 세우고 실천할수있도록 격려해주세요."
                "계획된 이벤트를 모두 완료했다면 칭찬해주고, 미완료된 이벤트가 남아있는경우 어떤 이벤트가 남아있는지 알려주세요."
                "요약 정보는 구어체로 작성되어야 하며, 최대 4문장을 넘기지 않도록 해주세요. "
                "요약 정보는 최대 100자 이내로 작성해주세요."
        ),
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
  Future<List<EventModel>> getEvents(String formattedCurDay, String userId, int flag) async {

    String sttfmtDate = "";
    String endfmtDate = "";

    if(flag == 1) { // 주별요약
      DateTime date = DateTime.parse(formattedCurDay);
      int weekday = date.weekday; // 요일 알아내기 (1:월요일, 7:일요일)
      // 주의 시작일 : 일요일
      DateTime sttWeek = date.subtract(Duration(days:weekday%7));
      // 주의 종료일 : 토요일
      DateTime endWeek = sttWeek.add(Duration(days: 6));

      sttfmtDate = sttWeek.toIso8601String().split('T')[0];
      endfmtDate = endWeek.toIso8601String().split('T')[0];
    }else if(flag == 2){ //월별요약
      DateTime date = DateTime.parse(formattedCurDay);
      DateTime lastDay = DateTime(date.year, date.month + 1, 0); // 마지막달에서 -1

      sttfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-01";
      endfmtDate = lastDay.toIso8601String().split('T')[0];
    }else{
      sttfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";
      endfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";
    }

    // events의 eventDate필드는 string으로 '2024-08-12T00:00:00.000' 형식으로 저장됨을 확인함 (파이어베이스)
    // 그래서 날짜 비교가 아니라 문자열 비교해야함.
    //DateTime sttDate = DateTime.parse(_formattedCurDay);
    //DateTime endDate = DateTime(sttDate.year, sttDate.month, sttDate.day, 23, 59, 59);
    //String sttfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";
    //String endfmtDate = "${formattedCurDayEnd.substring(0, 4)}-${formattedCurDayEnd.substring(4, 6)}-${formattedCurDayEnd.substring(6, 8)}";
    QuerySnapshot snapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .where('eventDate', isGreaterThanOrEqualTo: "${sttfmtDate}T00:00:00.000")
        .where('eventDate', isLessThanOrEqualTo: "${endfmtDate}T23:59:59.999")
        .get();

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
        completedYn: data['completedYn'] ?? 'N',
        isRecurring: data['isRecurring'] ?? false,
        originalEventId: doc.id, // 문서 ID를 originalEventId로 사용
      );
    }).toList();
    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  /**
   * 이벤트 결과 조회
   */
  Future<List<EventResultModel>> getEventResults(String formattedCurDay, String userId, int flag) async {
    String sttfmtDate = "";
    String endfmtDate = "";

    if(flag == 1) { // 주별요약
      DateTime date = DateTime.parse(formattedCurDay);
      int weekday = date.weekday; // 요일 알아내기 (1:월요일, 7:일요일)
      // 주의 시작일 : 일요일
      DateTime sttWeek = date.subtract(Duration(days:weekday%7));
      // 주의 종료일 : 토요일
      DateTime endWeek = sttWeek.add(Duration(days: 6));

      sttfmtDate = sttWeek.toIso8601String().split('T')[0];
      endfmtDate = endWeek.toIso8601String().split('T')[0];
    }else if(flag == 2){ //월별요약
      DateTime date = DateTime.parse(formattedCurDay);
      DateTime lastDay = DateTime(date.year, date.month + 1, 0); // 마지막달에서 -1

      sttfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-01";
      endfmtDate = lastDay.toIso8601String().split('T')[0];
    }else{
      sttfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";
      endfmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";
    }

    //DateTime sttDate = DateTime.parse(_formattedCurDay);
    //DateTime endDate = DateTime(sttDate.year, sttDate.month, sttDate.day, 23, 59, 59);
    //String fmtDate = "${formattedCurDay.substring(0, 4)}-${formattedCurDay.substring(4, 6)}-${formattedCurDay.substring(6, 8)}";

    QuerySnapshot snapshot = await _firestore
        .collection('result_events')
        .where('userId', isEqualTo: userId)
        .where('eventResultDate', isGreaterThanOrEqualTo: "${sttfmtDate}T00:00:00.000")
        .where('eventResultDate', isLessThanOrEqualTo: "${endfmtDate}T23:59:59.999")
        .get();
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
        completedYn: data['completedYn'] ?? '',
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

