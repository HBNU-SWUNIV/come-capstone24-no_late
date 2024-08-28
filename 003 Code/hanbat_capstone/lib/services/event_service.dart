import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<EventModel>> getEventsForDate(DateTime date, {bool forCalendar = false}) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('eventDate', isGreaterThanOrEqualTo: startOfDayStr)
          .where('eventDate', isLessThanOrEqualTo: endOfDayStr)

          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((event) => !forCalendar || event.showOnCalendar)
          .toList();

      final recurringSnapshot = await _firestore
          .collection('events')
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
      return [];
    }
  }
  Future<void> updateEventCompletedStatus(String formattedDate, int hour, String status) async {
    final eventDate = DateTime.parse(formattedDate);
    final eventStartTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour);
    final eventEndTime = eventStartTime.add(Duration(hours: 1));

    final snapshot = await _firestore
        .collection('events')
        .where('eventDate', isEqualTo: eventDate.toIso8601String())

        .get();

    for (var doc in snapshot.docs) {
      final event = EventModel.fromMap(doc.data());
      if (event.eventSttTime != null &&
          event.eventEndTime != null &&
          event.eventSttTime!.isBefore(eventEndTime) &&
          event.eventEndTime!.isAfter(eventStartTime)) {
        await doc.reference.update({'completedYn': status});
      }
    }
  }
  Future<void> toggleEventCompletedStatus(String eventId) async {
    final docSnapshot = await _firestore.collection('events').doc(eventId).get();

    if (docSnapshot.exists) {
      final event = EventModel.fromMap(docSnapshot.data()!);
      final newStatus = event.completedYn == 'Y' ? 'N' : 'Y';

      await docSnapshot.reference.update({'completedYn': newStatus});
    }
  }


  Future<List<EventResultModel>> getResultEventsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      final QuerySnapshot snapshot = await _firestore
          .collection('result_events')
          .where('eventResultDate', isGreaterThanOrEqualTo: startOfDayStr)
          .where('eventResultDate', isLessThanOrEqualTo: endOfDayStr)
          .get();

      final List<EventResultModel> resultEvents = snapshot.docs
          .map((doc) => EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return resultEvents;
    } catch (e) {
      print('Error fetching result events: $e');
      return [];
    }
  }




  List<Map<String, String>> generateScheduleData(
      DateTime selectedDate,
      int startTime,
      int endTime,
      List<EventModel> events,
      List<EventResultModel> resultEvents) {
    return List.generate(endTime - startTime + 1, (index) {
      final eventTimeStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime + index,
      );
      final eventTimeEnd = eventTimeStart.add(Duration(hours: 1));

      final eventsForTime = events.where((event) =>
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

  Future<List<bool>> loadCheckboxStatesForDate(String formattedDate) async {
    final resultEvents = await getResultEventsForDate(DateTime.parse(formattedDate));
    List<bool> checkboxStates = List.generate(24, (_) => false);

    for (var event in resultEvents) {
      if (event.eventResultSttTime != null) {
        int startHour = event.eventResultSttTime!.hour;
        int endHour = event.eventResultEndTime?.hour ?? (startHour + 1);
        for (int i = startHour; i < endHour && i < 24; i++) {
          checkboxStates[i] = true;
        }
      }
    }

    return checkboxStates;
  }






  Future<void> copyEventToResult(String formattedDate, int index, int startTime) async {
    final scheduleData = generateScheduleData(
        DateTime.parse(formattedDate),
        startTime,
        startTime + 23,  // 하루의 끝을 나타내는 값으로 수정 필요할 수 있음
        await getEventsForDate(DateTime.parse(formattedDate)),
        await getResultEventsForDate(DateTime.parse(formattedDate))
    );

    final planTitle = scheduleData[index]['plan'];
    if (planTitle != null && planTitle.isNotEmpty) {
      final eventDate = DateTime.parse(formattedDate);
      final eventStartTime = DateTime(
          eventDate.year, eventDate.month, eventDate.day, startTime + index);

      // 기존에 저장된 동일한 계획 이벤트가 있는지 확인
      final existingResultSnapshot = await FirebaseFirestore.instance
          .collection('result_events')
          .where('eventResultDate', isEqualTo: eventDate.toIso8601String())
          .where('eventResultTitle', isEqualTo: planTitle)
          .get();

      if (existingResultSnapshot.docs.isNotEmpty) {
        // 기존 이벤트가 있다면 종료 시간을 1시간 늘림
        final existingResultData = existingResultSnapshot.docs.first.data();
        final existingResult = EventResultModel.fromMap(existingResultData);
        final newEndTime = existingResult.eventResultEndTime!.add(Duration(hours: 1));

        await FirebaseFirestore.instance
            .collection('result_events')
            .doc(existingResult.eventResultId)
            .update({'eventResultEndTime': newEndTime.toIso8601String()});

      } else {
        // 기존 이벤트가 없다면 새 이벤트 생성
        final eventSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .where('eventDate', isEqualTo: eventDate.toIso8601String())
            .where('eventTitle', isEqualTo: planTitle)
            .get();

        if (eventSnapshot.docs.isNotEmpty) {
          final eventData = eventSnapshot.docs.first.data();
          final event = EventModel.fromMap(eventData);

          final eventResult = EventResultModel(
            eventResultId: FirebaseFirestore.instance.collection('result_events').doc().id,
            eventId: event.eventId,
            categoryId: event.categoryId,
            userId: event.userId,
            eventResultDate: eventDate,
            eventResultSttTime: eventStartTime,
            eventResultEndTime: eventStartTime.add(Duration(hours: 1)),
            eventResultTitle: event.eventTitle,
            eventResultContent: event.eventContent,
            isAllDay: event.isAllDay,
            completeYn: 'Y',
          );

          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(eventResult.eventResultId)
              .set(eventResult.toMap());

        } else {
          print('No matching event found in Firestore.');
        }
      }
    } else {
      print('No planTitle found for index $index.');
    }
  }

  Future<List<bool>> loadCheckboxStates() async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(24, (index) => prefs.getBool('checkbox_$index') ?? false);
  }

  // lib/services/event_service.dart 파일에 추가

  Future<void> deleteEvent(String collectionName, String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(eventId)
          .delete();
      print('Event deleted successfully');
    } catch (e) {
      print('Error deleting event: $e');
      throw e; // 에러를 상위로 전파하여 UI에서 처리할 수 있게 함
    }
  }
  Future<void> saveTimeBasedCheckboxState(String date, int hour, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${date}_checkbox_$hour';
    await prefs.setBool(key, state);
  }
  Future<Map<int, bool>> loadTimeBasedCheckboxStatesForDate(String formattedDate) async {
    final prefs = await SharedPreferences.getInstance();
    Map<int, bool> states = {};

    for (int i = 0; i < 24; i++) {
      final key = '${formattedDate}_checkbox_$i';
      states[i] = prefs.getBool(key) ?? false;
    }

    final resultEvents = await getResultEventsForDate(DateTime.parse(formattedDate));
    for (var event in resultEvents) {
      if (event.eventResultSttTime != null) {
        int startHour = event.eventResultSttTime!.hour;
        int endHour = event.eventResultEndTime?.hour ?? (startHour + 1);
        for (int i = startHour; i < endHour && i < 24; i++) {
          states[i] = true;
          await saveTimeBasedCheckboxState(formattedDate, i, true);
        }
      }
    }

    return states;
  }
}