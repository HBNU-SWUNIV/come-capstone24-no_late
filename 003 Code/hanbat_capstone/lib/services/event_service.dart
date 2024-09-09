import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<EventModel> allDayEvents = [];
  List<EventModel> regularEvents = [];
  List<EventResultModel> allDayResultEvents = [];
  List<EventResultModel> regularResultEvents = [];


  void setUserId(String userId) {
    _userId = userId;
  }



  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    return user.uid;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> ensureUserLoggedIn() async {
    if (_auth.currentUser == null) {
      throw Exception('User is not logged in');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      EventService().setUserId(user.uid);
    }
  }

  Future<Map<String, bool>> loadAllDayEventStatesForDate(String formattedDate) async {
    await ensureUserLoggedIn();
    final eventDate = DateTime.parse(formattedDate);
    Map<String, bool> states = {};

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isEqualTo: eventDate.toIso8601String())
          .where('isAllDay', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final event = EventModel.fromMap(doc.data());
        states[event.eventId] = event.completedYn == 'Y';
      }
    } catch (e) {
      print('Error loading all-day event states: $e');
    }

    return states;
  }

  Future<void> updateAllDayEventState(String formattedDate, String eventId, bool isCompleted) async {
    await ensureUserLoggedIn();
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({'completedYn': isCompleted ? 'Y' : 'N'});

      // 결과 이벤트 업데이트 또는 생성
      final eventDate = _normalizeDate(DateTime.parse(formattedDate));

      if (isCompleted) {
        // 완료된 경우에만 result_events에 추가 또는 업데이트
        final eventSnapshot = await _firestore.collection('events').doc(eventId).get();
        final event = EventModel.fromMap(eventSnapshot.data()!);

        final resultEventSnapshot = await _firestore
            .collection('result_events')
            .where('eventId', isEqualTo: eventId)
            .where('eventResultDate', isEqualTo: eventDate.toUtc().toIso8601String())
            .get();

        if (resultEventSnapshot.docs.isEmpty) {
          // 새 결과 이벤트 생성
          final resultEvent = EventResultModel(
            eventResultId: _firestore.collection('result_events').doc().id,
            eventId: event.eventId,
            categoryId: event.categoryId,
            userId: event.userId,
            eventResultDate: eventDate,
            eventResultSttTime: DateTime(eventDate.year, eventDate.month, eventDate.day),
            eventResultEndTime: DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59, 59),
            eventResultTitle: event.eventTitle,
            eventResultContent: event.eventContent,
            isAllDay: true,
            completeYn: 'Y',
          );

          await _firestore
              .collection('result_events')
              .doc(resultEvent.eventResultId)
              .set(resultEvent.toMap());
        } else {
          // 기존 결과 이벤트 업데이트
          await _firestore
              .collection('result_events')
              .doc(resultEventSnapshot.docs.first.id)
              .update({'completeYn': 'Y'});
        }
      } else {
        // 완료 취소 시 result_events에서 제거
        final resultEventSnapshot = await _firestore
            .collection('result_events')
            .where('eventId', isEqualTo: eventId)
            .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
            .get();

        if (resultEventSnapshot.docs.isNotEmpty) {
          await _firestore
              .collection('result_events')
              .doc(resultEventSnapshot.docs.first.id)
              .delete();
        }
      }
    } catch (e) {
      print('Error updating all-day event state: $e');
      throw e;
    }
  }



  Future<List<EventModel>> getEventsForDate(DateTime date, {bool forCalendar = false, bool excludeAllDay = false}) async {
    await ensureUserLoggedIn();
    try {
      final normalizedDate = _normalizeDate(date);
      final startOfDay = normalizedDate.toUtc();
      final endOfDay = normalizedDate.add(Duration(days: 1));

      print("Querying events from ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}");

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)


          .where('eventDate', isGreaterThanOrEqualTo: startOfDay.toUtc().toIso8601String())
          .where('eventDate', isLessThan: endOfDay.toUtc().toIso8601String())  // 다음 날까지 포함
          .get();

      print("Found ${snapshot.docs.length} events in Firestore");

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((event) => !excludeAllDay || !event.isAllDay != true)
          .toList();

      events = events.where((event) {
        if (event.isAllDay) {
          final eventDate = _normalizeDate(event.eventDate!);
          return eventDate.isAtSameMomentAs(normalizedDate);
        }
        return true;
      }).toList();

      allDayEvents = events.where((event) => event.isAllDay).toList();
      regularEvents = events.where((event) => !event.isAllDay).toList();



      QuerySnapshot recurringSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)  // 사용자 ID로 필터링
          .where('isRecurring', isEqualTo: true)
          .get();

      for (var doc in recurringSnapshot.docs) {
        final recurringEvent = EventModel.fromMap(doc.data() as Map<String, dynamic>);
        if (recurringEvent.eventDate != null) {
          final daysDifference = date.difference(recurringEvent.eventDate!).inDays;
          if (daysDifference >= 0 && daysDifference % 7 == 0 && daysDifference < 28) {
            // 반복 이벤트의 복사본을 만들고 날짜를 현재 날짜로 조정
            final adjustedEvent = recurringEvent.copyWith(
              eventDate: date,
              eventSttTime: DateTime(
                date.year,
                date.month,
                date.day,
                recurringEvent.eventSttTime!.hour,
                recurringEvent.eventSttTime!.minute,
              ),
              eventEndTime: DateTime(
                date.year,
                date.month,
                date.day,
                recurringEvent.eventEndTime!.hour,
                recurringEvent.eventEndTime!.minute,
              ),
            );
            events.add(adjustedEvent);
          }
        }
      }
      return events;
    } catch (e) {
      print('Error fetching events: $e');
      rethrow;
    }
  }

  Future<void> toggleEventCompletedStatus(String eventId) async {
    await ensureUserLoggedIn();
    final docSnapshot = await _firestore.collection('events').doc(eventId).get();

    if (docSnapshot.exists) {
      final event = EventModel.fromMap(docSnapshot.data()!);
      if(event.userId == userId) {
        final newStatus = event.completedYn == 'Y' ? 'N' : 'Y';
        await docSnapshot.reference.update({'completedYn': newStatus});
      }

    }
  }
  // Future<void> movePlanToActual(String formattedDate, int hour, EventModel event) async {
  //   final eventDate = DateTime.parse(formattedDate);
  //   final eventStartTime = DateTime(eventDate.year, eventDate.month, eventDate.day, event.eventSttTime!.hour);
  //   final eventEndTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour + 1);
  //
  //   // result_events 컬렉션에 새로운 이벤트 생성
  //   final resultEventData = EventResultModel(
  //     eventResultId: _firestore.collection('result_events').doc().id,
  //     eventId: event.eventId,
  //     categoryId: event.categoryId,
  //     userId: event.userId,
  //     eventResultDate: eventDate,
  //     eventResultSttTime: eventStartTime,
  //     eventResultEndTime: eventEndTime,
  //     eventResultTitle: event.eventTitle,
  //     eventResultContent: event.eventContent,
  //     isAllDay: false,
  //     completeYn: 'Y',
  //   );
  //
  //   await _firestore
  //       .collection('result_events')
  //       .doc(resultEventData.eventResultId)
  //       .set(resultEventData.toMap());
  //
  //   // 원본 이벤트 업데이트
  //   await _firestore
  //       .collection('events')
  //       .doc(event.eventId)
  //       .update({
  //     'completedYn': 'Y',
  //     'lastCompletedHour': hour + 1,
  //   });
  // }

  Future<List<EventModel>> getAllDayEventsForDate(DateTime date) async {
    await ensureUserLoggedIn();
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
      final endOfDay = startOfDay.add(Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('eventDate', isLessThan: endOfDay.toIso8601String())
          .where('isAllDay', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all-day events: $e');
      rethrow;
    }
  }

  Future<List<EventModel>> getTimeBasedEventsForDate(DateTime date) async {
    await ensureUserLoggedIn();
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
      final endOfDay = startOfDay.add(Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('eventDate', isLessThan: endOfDay.toIso8601String())
          .where('isAllDay', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching time-based events: $e');
      rethrow;
    }
  }

  // 종일 일정에 대한 체크박스 상태 로드
  Future<Map<String, bool>> loadAllDayEventStates(DateTime date) async {
    await ensureUserLoggedIn();
    final allDayEvents = await getAllDayEventsForDate(date);
    return {for (var event in allDayEvents) event.eventId: event.completedYn == 'Y'};
  }

  // 시간별 일정에 대한 체크박스 상태 로드
  Future<Map<int, bool>> loadTimeBasedCheckboxStatesForDate(String formattedDate) async {
    await ensureUserLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    Map<int, bool> states = {};

    for (int i = 0; i <= 24; i++) {
      final key = '${userId}_${formattedDate}_checkbox_$i';
      states[i] = prefs.getBool(key) ?? false;
    }



    return states;
  }
  Future<void> handleCheckboxChange(String formattedDate, int hour, bool newState) async {
    await saveTimeBasedCheckboxState(formattedDate, hour, newState);

    final eventDate = DateTime.parse(formattedDate);
    if (newState) {
      await createOrUpdateResultEvent(formattedDate, hour, hour);
    } else {
      await removeResultEvent(formattedDate, hour, ''); // eventId는 빈 문자열로 전달
    }
  }

  Future<void> updateResultEventCompleteStatus(String eventResultId, bool isCompleted) async {
    await _firestore
        .collection('result_events')
        .doc(eventResultId)
        .update({'completeYn': isCompleted ? 'Y' : 'N'});
  }

  List<Map<String, String>> generateScheduleData(
      DateTime selectedDate,
      int startTime,
      int endTime,
      List<EventModel> events,
      List<EventResultModel> resultEvents) {
    return List.generate(endTime - startTime + 2, (index) {
      final hour = startTime + index;
      final eventTimeStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
          hour
      );
      final eventTimeEnd = eventTimeStart.add(Duration(hours: 1));

      final eventsForTime = events.where((event) =>
      !event.isAllDay &&
          event.eventSttTime != null &&
          event.eventEndTime != null &&
          eventTimeStart.isBefore(event.eventEndTime!) &&
          eventTimeEnd.isAfter(event.eventSttTime!)).toList();

      final resultEventsForTime = resultEvents.where((resultEvent) {
        try {
          final retSttTime = resultEvent.eventResultSttTime;
          final retEndTime = resultEvent.eventResultEndTime;

          if (retSttTime != null && retEndTime != null) {
            return (eventTimeStart.isBefore(retEndTime) ||
                eventTimeStart.isAtSameMomentAs(retSttTime)) &&
                (eventTimeEnd.isAfter(retSttTime) ||
                    eventTimeEnd.isAtSameMomentAs(retEndTime));
          }
          return false;
        } catch (e) {
          print('Invalid date format in result event: $e');
          return false;
        }
      }).toList();

      final eventForTime = eventsForTime.isNotEmpty ? eventsForTime.first : null;
      final resultEventForTime = resultEventsForTime.isNotEmpty ? resultEventsForTime.first : null;

      return {
        'plan': eventForTime?.eventTitle ?? '',
        'planCategoryId': eventForTime?.categoryId ?? '',
        'actual': resultEventForTime?.eventResultTitle ?? '',
        'actualCategoryId': resultEventForTime?.categoryId ?? '',
        'completedYn': eventForTime?.completedYn ?? 'N', //
        'eventId': eventForTime?.eventId ?? '',
      };
    });
  }


  Future<void> movePlanToActual(String formattedDate, int hour, EventModel event) async {
    final eventDate = DateTime.parse(formattedDate);
    final eventStartTime = DateTime(eventDate.year, eventDate.month, eventDate.day, event.eventSttTime!.hour);
    DateTime eventEndTime;
      eventEndTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour + 1);
    // result_events 컬렉션에서 해당 이벤트 찾기
    final resultEventSnapshot = await _firestore
        .collection('result_events')
        .where('eventId', isEqualTo: event.eventId)
        .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
        .get();
    if (resultEventSnapshot.docs.isEmpty) {
      // 새로운 result_event 생성
      final resultEventData = EventResultModel(
        eventResultId: _firestore.collection('result_events').doc().id,
        eventId: event.eventId,
        categoryId: event.categoryId,
        userId: event.userId,
        eventResultDate: eventDate,
        eventResultSttTime: eventStartTime,
        eventResultEndTime: eventEndTime,
        eventResultTitle: event.eventTitle,
        eventResultContent: event.eventContent,
        isAllDay: false,
        completeYn: '',
      );
      await _firestore
          .collection('result_events')
          .doc(resultEventData.eventResultId)
          .set(resultEventData.toMap());
    } else {
      // 기존 result_event 업데이트
      final resultEventDoc = resultEventSnapshot.docs.first;
      await resultEventDoc.reference.update({
        'eventResultEndTime': eventEndTime.toIso8601String(),
      });
    }
    // 원본 이벤트 업데이트
    await _firestore
        .collection('events')
        .doc(event.eventId)
        .update({
      'completedYn': 'Y',
      'lastCompletedHour': hour + 1,
    });
    // 체크박스 상태 저장
    await saveTimeBasedCheckboxState(formattedDate, hour, true);
  }

  Future<void> removeResultEvent(String formattedDate, int hour, String eventId) async {
    final eventDate = DateTime.parse(formattedDate);
    final eventEndTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour);

    // result_events 컬렉션에서 해당 이벤트 찾기
    final resultEventSnapshot = await _firestore
        .collection('result_events')
        .where('eventId', isEqualTo: eventId)
        .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
        .get();

    if (resultEventSnapshot.docs.isNotEmpty) {
      final resultEventDoc = resultEventSnapshot.docs.first;
      final resultEventData = resultEventDoc.data();
      final currentEndTime = DateTime.parse(resultEventData['eventResultEndTime'] as String);

      if (currentEndTime.hour > hour) {
        // 종료 시간 업데이트
        await resultEventDoc.reference.update({
          'eventResultEndTime': eventEndTime.toIso8601String(),
        });
      } else {
        // result_event 삭제
        await resultEventDoc.reference.delete();
      }
    }

    // 원본 이벤트 업데이트
    final eventDoc = await _firestore
        .collection('events')
        .doc(eventId)
        .get();

    if (eventDoc.exists) {
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final lastCompletedHour = eventData['lastCompletedHour'] as int?;

      if (lastCompletedHour == hour) {
        await eventDoc.reference.update({
          'completedYn': 'N',
          'lastCompletedHour': FieldValue.delete(),
        });
      } else if (lastCompletedHour != null && lastCompletedHour > hour) {
        await eventDoc.reference.update({
          'lastCompletedHour': hour - 1,
        });
      }
    }

    // 체크박스 상태 저장
    await saveTimeBasedCheckboxState(formattedDate, hour, false);
  }

  Future<void> updateEventCompletedStatus(String eventId, String status) async {
    await ensureUserLoggedIn();
    await _firestore
        .collection('events')
        .doc(eventId)
        .update({'completedYn': status});
  }

  Future<void> createOrUpdateResultEvent(String formattedDate, int hour, int startTime) async {
    await ensureUserLoggedIn();
    final eventDate = DateTime.parse(formattedDate);
    final eventStartTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour);
    final eventEndTime = eventStartTime.add(Duration(hours: 1));

    // 해당 날짜의 모든 이벤트를 가져옵니다.
    final eventSnapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .where('eventDate', isEqualTo: eventDate.toIso8601String())
        .get();

    // 가져온 이벤트 중 해당 시간대와 겹치는 이벤트를 찾습니다.
    final matchingEvents = eventSnapshot.docs.where((doc) {
      final event = EventModel.fromMap(doc.data());
      return event.eventSttTime!.isBefore(eventEndTime) &&
          event.eventEndTime!.isAfter(eventStartTime);
    }).toList();

    if (matchingEvents.isNotEmpty) {
      // 겹치는 이벤트가 있다면, 첫 번째 이벤트를 사용합니다.
      final eventDoc = matchingEvents.first;
      final event = EventModel.fromMap(eventDoc.data());

      // 결과 이벤트 생성 또는 업데이트
      final existingResultSnapshot = await _firestore
          .collection('result_events')
          .where('userId', isEqualTo: userId)
          .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
          .where('eventResultSttTime', isEqualTo: eventStartTime.toIso8601String())
          .get();

      if (existingResultSnapshot.docs.isEmpty) {
        // 새 결과 이벤트 생성
        final eventResult = EventResultModel(
          eventResultId: _firestore.collection('result_events').doc().id,
          eventId: event.eventId,
          categoryId: event.categoryId,
          userId: event.userId,
          eventResultDate: eventDate,
          eventResultSttTime: eventStartTime,
          eventResultEndTime: eventEndTime,
          eventResultTitle: event.eventTitle,
          eventResultContent: event.eventContent,
          isAllDay: false,
          completeYn: 'N',  // 기본값을 'N'으로 설정
        );

        await _firestore
            .collection('result_events')
            .doc(eventResult.eventResultId)
            .set(eventResult.toMap());
      }
    }
  }



  Future<List<EventResultModel>> getResultEventsForDate(DateTime date,{bool excludeAllDay = false}) async {
    await ensureUserLoggedIn();
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final QuerySnapshot snapshot = await _firestore
          .collection('result_events')
          .where('userId', isEqualTo: userId)  // 사용자 ID로 필터링
          .where('isAllDay', isEqualTo: false)
          .where('eventResultDate', isGreaterThanOrEqualTo: startOfDay.toUtc().toIso8601String())
          .where('eventResultDate', isLessThan: endOfDay.toUtc().toIso8601String())
          .get();

      final List<EventResultModel> resultEvents = snapshot.docs
          .map((doc) => EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((event) => !excludeAllDay || event.isAllDay != true)
          .toList();


      return resultEvents;
    } catch (e) {
      print('Error fetching result events: $e');
      return [];
    }
  }






  Future<List<bool>> loadCheckboxStatesForDate(String formattedDate) async {
    await ensureUserLoggedIn();
    final resultEvents = await getResultEventsForDate(DateTime.parse(formattedDate));
    List<bool> checkboxStates = List.generate(25, (_) => false);

    for (var event in resultEvents) {
      if (event.eventResultSttTime != null) {
        int startHour = event.eventResultSttTime!.hour;
        int endHour = event.eventResultEndTime?.hour ?? (startHour + 1);
        for (int i = startHour; i < endHour && i <= 24; i++) {
          checkboxStates[i] = true;
        }
      }
    }

    return checkboxStates;
  }








  Future<void> copyEventToResult(String formattedDate, int index, int startTime) async {
    await ensureUserLoggedIn();
    final eventDate = DateTime.parse(formattedDate);
    final eventStartTime = DateTime(eventDate.year, eventDate.month, eventDate.day, startTime + index);
    final eventEndTime = eventStartTime.add(Duration(hours: 1));

    print("Searching for event on date: ${eventDate.toIso8601String()}, start time: $eventStartTime, end time: $eventEndTime");

    try {
      // 해당 시간대의 이벤트 찾기
      final eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventDate', isEqualTo: eventDate.toIso8601String())

          .get();
      print("Found ${eventSnapshot.docs.length} events for the date");
      final matchingEvents = eventSnapshot.docs.where((doc) {
        final eventData = doc.data();
        final eventSttTime = DateTime.parse(eventData['eventSttTime'] as String);
        final eventEndTime = DateTime.parse(eventData['eventEndTime'] as String);
        return (eventSttTime.isBefore(eventEndTime) || eventSttTime.isAtSameMomentAs(eventEndTime)) &&
            (eventEndTime.isAfter(eventStartTime) || eventEndTime.isAtSameMomentAs(eventStartTime));
      }).toList();

      print("Found ${matchingEvents.length} matching events");


      if (matchingEvents.isNotEmpty) {
        final event = EventModel.fromMap(matchingEvents.first.data());
        print("Found matching event: ${event.eventTitle}");

        // 결과 이벤트 생성 또는 업데이트
        final existingResultSnapshot = await FirebaseFirestore.instance
            .collection('result_events')
            .where('userId', isEqualTo: userId)
            .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
            .where('eventResultTitle', isEqualTo: event.eventTitle)
            .get();

        if (existingResultSnapshot.docs.isNotEmpty) {
          // 기존 결과 이벤트 업데이트
          final existingResultData = existingResultSnapshot.docs.first.data();
          final existingResult = EventResultModel.fromMap(existingResultData);
          final newEndTime = existingResult.eventResultEndTime!.add(Duration(hours: 1));

          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(existingResult.eventResultId)
              .update({'eventResultEndTime': newEndTime.toIso8601String()});

          print("Updated existing result event: ${existingResult.eventResultTitle}");
        } else {
          // 새 결과 이벤트 생성
          final eventResult = EventResultModel(
            eventResultId: FirebaseFirestore.instance.collection('result_events').doc().id,
            eventId: event.eventId,
            categoryId: event.categoryId,
            userId: event.userId,
            eventResultDate: eventDate,
            eventResultSttTime: eventStartTime,
            eventResultEndTime: eventEndTime,
            eventResultTitle: event.eventTitle,
            eventResultContent: event.eventContent,
            isAllDay: event.isAllDay,
            completeYn: 'Y',
          );

          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(eventResult.eventResultId)
              .set(eventResult.toMap());

          print("Created new result event: ${eventResult.eventResultTitle}");
        }

        // 원본 이벤트의 완료 상태 업데이트
        await FirebaseFirestore.instance
            .collection('events')
            .doc(event.eventId)
            .update({'completedYn': 'Y'});

        print("Updated original event completed status: ${event.eventTitle}");
      } else {
        print("No matching event found in Firestore for the given time range.");
      }
    } catch (e) {
      print("Error in copyEventToResult: $e");
    }
  }

  Future<List<bool>> loadCheckboxStates() async {
    await ensureUserLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    return List.generate(24, (index) => prefs.getBool('checkbox_$index') ?? false);
  }

  // lib/services/event_service.dart 파일에 추가

  Future<void> deleteEvent(String collectionName, String eventId) async {
    await ensureUserLoggedIn();
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(eventId)
          .delete();

      final deletedEvent = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(eventId)
          .get();

      if (deletedEvent.exists) {
        final eventDate = deletedEvent.data()?['eventDate'] as String?;
        if (eventDate != null) {
          await loadTimeBasedCheckboxStatesForDate(eventDate.split('T')[0]);
        }
      }

      print('Event deleted successfully');


    } catch (e) {
      print('Error deleting event: $e');
      throw e; // 에러를 상위로 전파하여 UI에서 처리할 수 있게 함
    }
  }
  Future<void> saveTimeBasedCheckboxState(String date, int hour, bool state) async {
    await ensureUserLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    final key = '${userId}_${date}_checkbox_$hour';
    await prefs.setBool(key, state);
  }
}

