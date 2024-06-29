// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:hanbat_capstone/screen/Schedule_CRUD.dart';
// import 'package:intl/intl.dart';
// import 'package:hanbat_capstone/model/event_model.dart';
// import 'package:hanbat_capstone/model/event_result_model.dart';
// import 'package:hanbat_capstone/screen/add_event_screen.dart';
// import 'package:hanbat_capstone/screen/event_detail_screen.dart';
//
// class schedule_screen extends StatelessWidget {
//   final DateTime selectedDate;
//
//   schedule_screen({required this.selectedDate});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: TimeListView(selectedDate: selectedDate),
//     );
//   }
// }
//
// class TimeListView extends StatefulWidget {
//   final DateTime selectedDate;
//
//   TimeListView({required this.selectedDate});
//   @override
//   _TimeListViewState createState() => _TimeListViewState();
// }
//
// class _TimeListViewState extends State<TimeListView> {
//   late DateTime selectedDate;
//
//   final List<String> timeList = List.generate(24, (index) {
//     return '${index.toString().padLeft(2, '0')}:00';
//   });
//
//   List<EventModel> scheduleList = List.generate(24, (_) => EventModel(
//     eventId: '',
//     categoryId: '',
//     userId: '',
//     eventTitle: '',
//     allDayYn: 'N',
//   ));
//
//   List<EventResultModel> resultList = List.generate(24, (_) => EventResultModel(
//     eventResultId: '',
//     eventId: '',
//     categoryId: '',
//     userId: '',
//     eventResultDate: DateTime.now(),
//     eventResultSttTime: DateTime.now(),
//     eventResultEndTime: DateTime.now(),
//     eventResultTitle: '',
//     eventResultContent: '',
//     completeYn: 'N',
//   ));
//
//   List<bool> _isChecked = List.generate(24, (_) => false);
//
//   @override
//   void initState() {
//     super.initState();
//     selectedDate = widget.selectedDate;
//     _loadSchedules();
//     _loadResults();
//   }
//
//   Future<void> _loadSchedules() async {
//     try {
//       final selectedDate = DateTime(this.selectedDate.year, this.selectedDate.month, this.selectedDate.day);
//       final selectedDateStart = Timestamp.fromDate(selectedDate);
//       final selectedDateEnd = Timestamp.fromDate(selectedDate.add(Duration(days: 1)).subtract(Duration(milliseconds: 1)));
//
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('events')
//           .where('eventDate', isGreaterThanOrEqualTo: selectedDateStart)
//           .where('eventDate', isLessThanOrEqualTo: selectedDateEnd)
//           .get();
//
//       final schedules = querySnapshot.docs.map((doc) {
//         final eventData = doc.data();
//         return EventModel(
//           eventId: doc.id,
//           categoryId: eventData['categoryId'],
//           userId: eventData['userId'],
//           eventDate: (eventData['eventDate'] as Timestamp?)?.toDate(),
//           eventSttTime: (eventData['eventSttTime'] as Timestamp?)?.toDate(),
//           eventEndTime: (eventData['eventEndTime'] as Timestamp?)?.toDate(),
//           eventTitle: eventData['eventTitle'],
//           eventContent: eventData['eventContent'],
//           allDayYn: eventData['allDayYn'],
//         );
//       }).toList();
//
//       setState(() {
//         scheduleList = List.generate(24, (index) {
//           final time = timeList[index];
//           final matchingSchedules = schedules.where((schedule) {
//             final eventTime = DateFormat('HH:mm').format(schedule.eventSttTime ?? DateTime.now());
//             return eventTime == time;
//           }).toList();
//
//           if (matchingSchedules.isNotEmpty) {
//             return matchingSchedules.first;
//           } else {
//             return EventModel(
//               eventId: '',
//               categoryId: '',
//               userId: '',
//               eventTitle: '',
//               allDayYn: 'N',
//             );
//           }
//         });
//       });
//     } catch (e) {
//       print('Error loading schedules: $e');
//       // 에러 처리 로직 추가
//     }
//   }
//
//   Future<void> _loadResults() async {
//     try {
//       final results = await Schedule_CRUD.getEventResultsByDate(selectedDate);
//       setState(() {
//         resultList = List.generate(24, (index) {
//           final time = timeList[index];
//           final matchingResults = results.where((result) {
//             final resultTime = DateFormat('HH:mm').format(result.eventResultSttTime);
//             return resultTime == time;
//           }).toList();
//
//           if (matchingResults.isNotEmpty) {
//             return matchingResults.first;
//           } else {
//             return EventResultModel(
//               eventResultId: '',
//               eventId: '',
//               categoryId: '',
//               userId: '',
//               eventResultDate: selectedDate,
//               eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
//               eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
//               eventResultTitle: '',
//               eventResultContent: '',
//               completeYn: 'N',
//             );
//           }
//         });
//       });
//     } catch (e) {
//       print('Error loading results: $e');
//       // 에러 처리 로직 추가
//     }
//   }
//
//   void _updateDate(int daysOffset) {
//     setState(() {
//       selectedDate = selectedDate.add(Duration(days: daysOffset));
//       _isChecked = List.generate(24, (_) => false);
//       _loadSchedules();
//       _loadResults();
//     });
//   }
//
//   void _addSchedule(int index) async {
//     final eventModel = scheduleList[index];
//     if (eventModel.eventTitle.isEmpty) {
//       // 계획이 비어있는 경우 AddEventScreen 띄우기
//       final newEvent = await Navigator.push<EventModel>(
//         context,
//         MaterialPageRoute(builder: (context) => AddEventScreen(selectedDate: selectedDate)),
//       );
//       if (newEvent != null) {
//         // AddEventScreen에서 입력된 데이터를 Firestore에 추가
//         final eventRef = FirebaseFirestore.instance.collection('events').doc();
//         await eventRef.set({
//           'eventId': eventRef.id,
//           'categoryId': newEvent.categoryId,
//           'userId': newEvent.userId,
//           'eventDate': newEvent.eventDate,
//           'eventSttTime': newEvent.eventSttTime,
//           'eventEndTime': newEvent.eventEndTime,
//           'eventTitle': newEvent.eventTitle,
//           'eventContent': newEvent.eventContent,
//           'allDayYn': newEvent.allDayYn,
//         });
//         _loadSchedules(); // 일정 리스트 갱신
//       }
//     } else {
//       // 계획이 비어있지 않은 경우 EventDetailScreen 띄우기
//       await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => EventDetailScreen(
//           event: eventModel,
//           onEventDeleted: (bool deleteAllRecurrence) async {
//             if (deleteAllRecurrence) {
//               // 모든 반복 일정 삭제
//               await FirebaseFirestore.instance
//                   .collection('events')
//                   .where('eventId', isEqualTo: eventModel.eventId)
//                   .get()
//                   .then((snapshot) {
//                 for (DocumentSnapshot doc in snapshot.docs) {
//                   doc.reference.delete();
//                 }
//               });
//             } else {
//               // 현재 일정만 삭제
//               await FirebaseFirestore.instance.collection('events').doc(eventModel.eventId).delete();
//             }
//             _loadSchedules(); // 일정 리스트 갱신
//           },
//           onEventEdited: (editedEvent) async {
//             await FirebaseFirestore.instance.collection('events').doc(eventModel.eventId).update({
//               'eventTitle': editedEvent.eventTitle,
//               'eventContent': editedEvent.eventContent,
//               // 수정된 다른 필드들도 업데이트
//             });
//             _loadSchedules(); // 일정 리스트 갱신
//           },
//         )),
//       );
//     }
//   }
//
//   void _add_actually_Schedule(int index) async {
//     final eventResult = resultList[index];
//
//     final result = await showDialog<Map<String, String>>(
//       context: context,
//       builder: (context) {
//         String eventResultTitle = eventResult.eventResultTitle;
//         String eventResultContent = eventResult.eventResultContent;
//
//         return AlertDialog(
//           title: const Text('일정 결과 추가/수정'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 decoration: const InputDecoration(labelText: '결과 제목'),
//                 controller: TextEditingController(text: eventResultTitle),
//                 onChanged: (value) {
//                   eventResultTitle = value;
//                 },
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: '결과 내용'),
//                 controller: TextEditingController(text: eventResultContent),
//                 onChanged: (value) {
//                   eventResultContent = value;
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop({
//                   'eventResultTitle': eventResultTitle,
//                   'eventResultContent': eventResultContent,
//                 });
//               },
//               child: const Text('저장'),
//             ),
//             if (eventResult.eventResultId.isNotEmpty)
//               TextButton(
//                 onPressed: () async {
//                   await Schedule_CRUD.deleteEventResult(eventResult);
//                   _loadResults();
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('삭제'),
//               ),
//           ],
//         );
//       },
//     );
//
//     if (result != null) {
//       if (eventResult.eventResultId.isNotEmpty) {
//         // 기존 결과 수정
//         final updatedEventResult = eventResult.copyWith(
//           eventResultTitle: result['eventResultTitle']!,
//           eventResultContent: result['eventResultContent']!,
//         );
//         await Schedule_CRUD.updateEventResult(updatedEventResult);
//       } else {
//         // 새로운 결과 추가
//         final newEventResult = EventResultModel(
//           eventResultId: '${selectedDate.millisecondsSinceEpoch}:${index}',
//           eventId: 'eventId',
//           categoryId: 'categoryId',
//           userId: 'userId',
//           eventResultDate: selectedDate,
//           eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
//           eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
//           eventResultTitle: result['eventResultTitle']!,
//           eventResultContent: result['eventResultContent']!,
//           completeYn: 'N',
//         );
//         await Schedule_CRUD.createEventResult(newEventResult);
//       }
//       _loadResults();
//     }
//   }
//
//   void _copyPlanToActual(int index) async {
//     if (_isChecked[index]) {
//       final eventModel = scheduleList[index];
//       final newEventResult = EventResultModel(
//         eventResultId: '${selectedDate.millisecondsSinceEpoch}:${index}',
//         eventId: eventModel.eventId,
//         categoryId: eventModel.categoryId,
//         userId: eventModel.userId,
//         eventResultDate: selectedDate,
//         eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
//         eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
//         eventResultTitle: eventModel.eventTitle,
//         eventResultContent: eventModel.eventContent ?? '',
//         completeYn: 'N',
//       );
//
//       await Schedule_CRUD.createEventResult(newEventResult);
//       _loadResults();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double planColumnWidth = screenWidth * 0.3;
//     double actualColumnWidth = screenWidth * 0.3;
//     double timeColumnWidth = screenWidth * 0.15;
//     double adjustColumnWidth = screenWidth * 0.1;
//     String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: Icon(Icons.arrow_left),
//               onPressed: () => _updateDate(-1),
//             ),
//             Text(formattedDate),
//             IconButton(
//               icon: Icon(Icons.arrow_right),
//               onPressed: () => _updateDate(1),
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: DataTable(
//           columnSpacing: 5,
//           showCheckboxColumn: true,
//           columns: [
//             DataColumn(
//               label: Container(
//                 width: timeColumnWidth,
//                 child: Text('시간'),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 width: planColumnWidth,
//                 child: Text('일정'),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 width: actualColumnWidth,
//                 child: Text('결과'),
//               ),
//             ),
//           ],
//           rows: List.generate(
//             timeList.length,
//                 (index) => DataRow(
//               selected: _isChecked[index],
//               onSelectChanged: (value) {
//                 setState(() {
//                   _isChecked[index] = value!;
//                   if (value) {
//                     _copyPlanToActual(index);
//                   }
//                 });
//               },
//               cells: [
//                 DataCell(
//                   Container(
//                     width: timeColumnWidth,
//                     child: Text(
//                       timeList[index],
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//                 DataCell(
//                   Container(
//                     width: planColumnWidth,
//                     child: Text(
//                       scheduleList[index].eventTitle,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   onTap: () {
//                     _addSchedule(index);
//                   },
//                 ),
//                 DataCell(
//                   Container(
//                     width: actualColumnWidth,
//                     child: Text(
//                       resultList[index].eventResultTitle,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   onTap: () {
//                     _add_actually_Schedule(index);
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeListView extends StatefulWidget {
  final DateTime? selectedDate;

  TimeListView({required this.selectedDate});

  @override
  _TimeListViewState createState() => _TimeListViewState();
}

class _TimeListViewState extends State<TimeListView> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, String>>> scheduleData = {};
  int startTime = 0;
  int endTime = 23;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<EventModel> events = [];
  late String formattedDate;
  List<EventResultModel> resultEventsForTime = [];
  List<bool> selectedStates = List.generate(24, (index) => false);

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      selectedDate = widget.selectedDate!;
    }
    formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    _initScheduleList();
    _fetchEvents();
    _loadCheckboxStates();
  }

  void updateCalendar() {
    // 캘린더 업데이트 로직 구현
    // 예를 들어, 선택된 날짜를 기준으로 일정을 다시 가져오는 등의 작업 수행
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = await getEventsForDate(selectedDate);
    final resultEvents = await getResultEventsForDate(selectedDate);

    print('Fetched events: $events');
    print('Fetched result events: $resultEvents');

    setState(() {
      scheduleData[formattedDate] = List.generate(timeList.length, (index) {
        final eventTimeStart = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          startTime + index,
        );
        final eventTimeEnd = eventTimeStart.add(Duration(hours: 1));

        final eventsForTime = events
            .where((event) =>
        event.eventSttTime != null &&
            event.eventEndTime != null &&
            eventTimeStart.isBefore(event.eventEndTime!) &&
            eventTimeEnd.isAfter(event.eventSttTime!))
            .toList();

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

        print('Events for time $eventTimeStart: $eventsForTime');
        print('Result events for time $eventTimeStart: $resultEventsForTime');

        final eventForTime =
        eventsForTime.isNotEmpty ? eventsForTime.first : null;

        final resultEventForTime =
        resultEventsForTime.isNotEmpty ? resultEventsForTime.first : null;

        return {
          'plan': eventForTime?.eventTitle ?? '',
          'actual': resultEventForTime?.eventResultTitle ?? '',
        };
      });
      print('Updated schedule data: $scheduleData');
      selectedStates = List.generate(timeList.length, (index) => false);
    });
  }

  void _updateDate(int daysOffset) {
    selectedDate = selectedDate.add(Duration(days: daysOffset));
    formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    _initScheduleList();
    _fetchEvents();
    selectedStates = List.generate(24, (index) => false);
  }

  Future<List<EventResultModel>> getResultEventsForDate(DateTime date) async {
    try {
      // 시작과 끝 시간을 정의합니다.
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // 날짜를 ISO 8601 형식의 문자열로 변환합니다.
      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('result_events')
          .where('eventResultDate', isGreaterThanOrEqualTo: startOfDayStr)
          .where('eventResultDate', isLessThanOrEqualTo: endOfDayStr)
          .get();

      final List<EventResultModel> resultEvents = snapshot.docs
          .map((doc) =>
          EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return resultEvents;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }

    //   // 결과 이벤트 가져오기
    //   try {
    //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
    //         .collection('result_events')
    //         .where('eventRetDate',
    //         isGreaterThanOrEqualTo:
    //         DateTime(date.year, date.month, date.day).toIso8601String())
    //         .where('eventRetDate',
    //         isLessThan: DateTime(date.year, date.month, date.day)
    //             .add(Duration(days: 1))
    //             .toIso8601String())
    //         .get();
    //
    //     final List<EventResultModel> resultEvents = snapshot.docs
    //         .map((doc) =>
    //         EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
    //         .toList();
    //
    //     return resultEvents;
    //   } catch (e) {
    //     print('Error fetching result events: $e');
    //     return [];
    //   }
    // }
  }

  List<String> get timeList =>
      List.generate(endTime - startTime + 1, (index) {
        int hour = startTime + index;
        return '${hour.toString().padLeft(2, '0')}:00';
      });

  List<Map<String, String>> get scheduleList =>
      List.generate(endTime - startTime + 1, (_) => {'plan': '', 'actual': ''});

  // Future<List<EventModel>> getEventsForDate(DateTime date) async {
  //   try {
  //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collection('events')
  //         .where('eventDate', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
  //         .get();
  //
  //     final List<EventModel> events = snapshot.docs
  //         .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
  //         .toList();
  //
  //     // final QuerySnapshot recurringSnapshot = await FirebaseFirestore.instance
  //     //     .collection('events')
  //     //     .where('isRecurring', isEqualTo: true)
  //     //     .get();
  //     //
  //     // final List<EventModel> recurringEvents = recurringSnapshot.docs
  //     //     .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
  //     //     .where((event) {
  //     //   final eventDate = event.eventDate;
  //     //   if (eventDate == null) return false;
  //     //   final eventDateTime = DateTime(
  //     //       eventDate.year, eventDate.month, eventDate.day);
  //     //   final difference = date
  //     //       .difference(eventDateTime)
  //     //       .inDays;
  //     //   return difference >= 0 && difference % 7 == 0;
  //     // })
  //     //     .toList();
  //     //
  //     // final List<EventModel> allEvents = [];
  //     // allEvents.addAll(events);
  //     // allEvents.addAll(recurringEvents);
  //     //
  //     // final Map<String, EventModel> eventMap = {};
  //     // for (final event in allEvents) {
  //     //   final key = '${event.eventTitle}_${event.eventSttTime}';
  //     //   if (!eventMap.containsKey(key)) {
  //     //     eventMap[key] = event;
  //     //   }
  //     // }
  //     //
  //     // return eventMap.values.toList();
  //     return events;
  //   } catch (e) {
  //     print('Error fetching events: $e');
  //     return [];
  //   }
  // }

  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    try {
      // 시작과 끝 시간을 정의합니다.
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // 날짜를 ISO 8601 형식의 문자열로 변환합니다.
      final startOfDayStr = startOfDay.toIso8601String();
      final endOfDayStr = endOfDay.toIso8601String();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventDate', isGreaterThanOrEqualTo: startOfDayStr)
          .where('eventDate', isLessThanOrEqualTo: endOfDayStr)
          .get();

      final List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return events;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        _fetchEvents();
      });
    }
  }

  Future<void> _updateEvent_plan(EventModel event, int index) async {
    await _updateEvent(context, 'events', event, index);
  }

  Future<void> _deleteEvent_plan(EventModel event) async {
    await _deleteEvent('events', event.eventId);
  }

  Future<void> _deleteEvent_actual(EventResultModel event) async {
    await _deleteEvent('result_events', event.eventResultId);
  }

  Future<void> _updateEvent_actual(EventResultModel event, int index) async {
    await _updateEvent(context, 'result_events', event, index);
  }

  void _initScheduleList() {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    if (scheduleData[formattedDate] == null) {
      scheduleData[formattedDate] = List.generate(
        endTime - startTime + 1,
            (_) => {'plan': '', 'actual': ''},
      );
    }
  }

  Future<void> _deleteEvent(String collectionName, String eventId) async {
    // 이벤트 삭제 메서드
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(eventId)
          .delete();
      _fetchEvents();
    } catch (e) {
      print('Error deleting event: $e');
      // 예외 처리 로직 추가 (예: 사용자에게 에러 메시지 표시)
    }
  }

  Future<void> _updateEvent(BuildContext context, // 이벤트 업데이트 메서드
      String collectionName,
      dynamic event,
      int index,) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddEventScreen(
                selectedDate: event.eventDate ??
                    DateTime.parse(event.eventRetDate),
                selectedTime:
                event.eventSttTime ?? DateTime.parse(event.eventRetSttTime),
                event: event is EventModel ? event : null,
                actualevent: event is EventResultModel ? event : null,
                isFinalEvent: collectionName == 'result_events',
              ),
        ),
      );

      if (result != null) {
        setState(() {
          if (collectionName == 'events') {
            scheduleData[formattedDate]?[index]['plan'] =
                (result as EventModel).eventTitle;
          } else {
            scheduleData[formattedDate]?[index]['actual'] =
                (result as EventResultModel).eventResultTitle;
          }
        });
      }
    } catch (e) {
      print('Error updating event: $e');
      // 예외 처리 로직 추가 (예: 사용자에게 에러 메시지 표시)
    }
  }

  // // 예시 사용법
  // await _deleteEvent('events', event.eventId);
  // await _deleteEvent('result_events', eventResult.eventRetId);
  //
  // await _updateEvent(context, 'events', event, index);
  // await _updateEvent(context, 'result_events', eventResult, index);

  void _copyEventToResult(int index) async {
    final planTitle = scheduleData[formattedDate]?[index]['plan'];
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

        setState(() {
          scheduleData[formattedDate]?[index]['actual'] = existingResult.eventResultTitle;
        });
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
            allDayYn: event.allDayYn,
            completeYn: 'Y',
          );

          await FirebaseFirestore.instance
              .collection('result_events')
              .doc(eventResult.eventResultId)
              .set(eventResult.toMap());

          setState(() {
            scheduleData[formattedDate]?[index]['actual'] = eventResult.eventResultTitle;
          });
        } else {
          print('No matching event found in Firestore.');
        }
      }
    } else {
      print('No planTitle found for index $index.');
    }
    _toggleCheckbox(index);
  }






  Future<void> _loadCheckboxStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedStates = List.generate(
          24, (index) => prefs.getBool('checkbox_$index') ?? false);
    });
  }

  void _addResultEvent(int index) async {
    final eventTitle = scheduleData[formattedDate]?[index]['plan'] ?? '';
    final eventDate = DateTime.parse(formattedDate);
    final eventStartTime = DateTime(
        eventDate.year, eventDate.month, eventDate.day, startTime + index);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          selectedDate: eventDate,
          selectedTime: eventStartTime,
          isFinalEvent: true,
          eventTitle: eventTitle,
        ),
      ),
    );

    if (result != null && result is EventResultModel) {
      final docRef = await FirebaseFirestore.instance
          .collection('result_events')
          .add(result.toMap());

      // 문서가 추가된 후 ID를 가져와서 실제 일정을 업데이트합니다.
      await FirebaseFirestore.instance
          .collection('result_events')
          .doc(docRef.id)
          .update({'eventRetId': docRef.id});

      setState(() {
        scheduleData[formattedDate]?[index]['actual'] = result.eventResultTitle;
      });
      _fetchEvents();
    }
  }

  void _toggleCheckbox(int index) {
    setState(() {
      selectedStates[index] = !selectedStates[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double planColumnWidth = screenWidth * 0.3;
    double actualColumnWidth = screenWidth * 0.3;
    double timeColumnWidth = screenWidth * 0.15;
    double adjustColumnWidth = screenWidth * 0.1;
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: () {
                  _updateDate(-1);
                  _fetchEvents();
                },
              ),
              Text(formattedDate),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: () {
                  _updateDate(1);
                  _fetchEvents();
                },
              ),
            ],
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.settings),
        //     onPressed: () {
        //       Navigator.of(context).push(
        //         MaterialPageRoute(
        //           builder: (context) =>
        //               SettingsScreen(
        //                 onTimeRangeChanged: (start, end) {
        //                   setState(() {
        //                     startTime = start;
        //                     endTime = end;
        //                     _initScheduleList();
        //                   });
        //                 },
        //                 initialStartTime: startTime,
        //                 initialEndTime: endTime,
        //               ),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 10,
          columns: [
            DataColumn(
              label: Container(
                width: adjustColumnWidth,
                child: Text(''),
              ),
            ),
            DataColumn(
              label: Container(
                width: timeColumnWidth,
                child: Text('시간'),
              ),
            ),
            DataColumn(
              label: Container(
                width: planColumnWidth,
                child: Text('일정'),
              ),
            ),
            DataColumn(
              label: Container(
                width: actualColumnWidth,
                child: Text('결과'),
              ),
            ),
          ],
          rows: List.generate(
            timeList.length,
            (index) => DataRow(cells: [
              DataCell(
                Row(children: [
                  IconButton(
                    icon: Icon(
                      selectedStates[index]
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    onPressed: () {
                      _toggleCheckbox(index);
                      _copyEventToResult(index);
                    },
                  ),
                ]),
              ),
              DataCell(
                Container(
                  width: timeColumnWidth,
                  child: Text(
                    timeList[index],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  width: planColumnWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          scheduleData[formattedDate]?[index]['plan'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  final eventTitle =
                      scheduleData[formattedDate]?[index]['plan'];
                  if (eventTitle == null || eventTitle.isEmpty) {
                    DateTime selectedDate = DateTime.parse(formattedDate);

                    DateTime selectedDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime + index,
                      0,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventScreen(
                          selectedDate: selectedDate,
                          selectedTime: selectedDateTime,
                        ),
                      ),
                    );
                  } else {
                    final eventDate = DateTime.parse(formattedDate);
                    final eventStartTime = DateTime(eventDate.year,
                        eventDate.month, eventDate.day, startTime + index);

                    // Firestore에서 이벤트 데이터 가져오기
                    final snapshot = await FirebaseFirestore.instance
                        .collection('events')
                        .where('eventDate',
                            isEqualTo: eventDate.toIso8601String())
                        .where('eventTitle', isEqualTo: eventTitle)
                        .get();

                    if (snapshot.docs.isNotEmpty) {
                      final eventData = snapshot.docs.first.data();
                      final event = EventModel.fromMap(eventData);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(
                            updateCalendar: updateCalendar,
                            selectedDate: selectedDate,
                            event: event,
                            onEventDeleted: (deleteAllRecurrences) async {
                              if (deleteAllRecurrences) {
                                final snapshot = await FirebaseFirestore
                                    .instance
                                    .collection('events')
                                    .where('eventTitle',
                                        isEqualTo: event.eventTitle)
                                    .where('isRecurring', isEqualTo: true)
                                    .get();
                                final batch =
                                    FirebaseFirestore.instance.batch();
                                for (final doc in snapshot.docs) {
                                  batch.delete(doc.reference);
                                }
                                await batch.commit();
                              } else {
                                await _updateEvent_plan(event, index);
                              }
                              _fetchEvents();
                            },
                            onEventEdited: (editedEvent) async {
                              if (editedEvent != null) {
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.eventId)
                                    .update(editedEvent.toMap());
                              }
                            },
                            onEventResultEdited: (editedEventResult) async {
                              if (editedEventResult != null) {
                                await FirebaseFirestore.instance
                                    .collection('result_events')
                                    .doc(editedEventResult.eventResultId)
                                    .update(editedEventResult.toMap());
                              }
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              DataCell(
                Container(
                  width: actualColumnWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          scheduleData[formattedDate]?[index]['actual'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  final eventTitle =
                      scheduleData[formattedDate]?[index]['actual'];
                  final planTitle =
                      scheduleData[formattedDate]?[index]['plan'] == eventTitle;

                  if (eventTitle == null || eventTitle.isEmpty) {

                    final planTitle = scheduleData[formattedDate]?[index]['plan'];
                    if (planTitle != null && planTitle is String && planTitle.isNotEmpty) {
                      // 계획된 일정이 있지만 결과가 없는 경우
                      _copyEventToResult(index);
                    } else {
                      // 계획된 일정도 없고 결과도 없는 경우
                      _addResultEvent(index);
                    }
                  } else {
                    final eventDate = DateTime.parse(formattedDate);
                    final eventSttTime = DateTime(eventDate.year,
                        eventDate.month, eventDate.day, startTime + index);

                    // Firestore에서 실제 이벤트 데이터 가져오기
                    final snapshot = await FirebaseFirestore.instance
                        .collection('result_events')
                        .where('eventResultDate',
                            isEqualTo: eventDate.toIso8601String())
                        .where('eventResultTitle', isEqualTo: eventTitle)
                        .get();

                    if (snapshot.docs.isNotEmpty) {
                      final eventData = snapshot.docs.first.data();
                      final eventResult = EventResultModel.fromMap(eventData);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(
                            eventResult: eventResult,
                            selectedDate: selectedDate,
                            updateCalendar: updateCalendar,
                            onEventDeleted: (deleteAllRecurrences) async {
                              await _deleteEvent_actual(eventResult);
                              _fetchEvents();
                            },
                            onEventEdited: (editedEvent) async {},
                            onEventResultEdited: (editedEventResult) async {
                              if (editedEventResult != null) {
                                await FirebaseFirestore.instance
                                    .collection('result_events')
                                    .doc(editedEventResult.eventResultId)
                                    .update(editedEventResult.toMap());
                                _fetchEvents();
                              }
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// class SettingsScreen extends StatelessWidget {
//   // 시간 범위 설정 화면
//   final Function(int, int) onTimeRangeChanged;
//   final int initialStartTimport 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../model/event_model.dart';
// import '../model/event_result_model.dart';
// import 'add_event_screen.dart';
// import 'event_detail_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class TimeListView extends StatefulWidget {
//   final DateTime? selectedDate;
//
//   TimeListView({required this.selectedDate});
//
//   @override
//   _TimeListViewState createState() => _TimeListViewState();
// }
//
// class _TimeListViewState extends State<TimeListView> {
//   DateTime selectedDate = DateTime.now();
//   Map<String, List<Map<String, String>>> scheduleData = {};
//   int startTime = 0;
//   int endTime = 23;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   List<EventModel> events = [];
//   late String formattedDate;
//   List<EventResultModel> resultEventsForTime = [];
//   List<bool> selectedStates = List.generate(24, (index) => false);
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.selectedDate != null) {
//       selectedDate = widget.selectedDate!;
//     }
//     formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//     _initScheduleList();
//     _fetchEvents();
//     _loadCheckboxStates();
//   }
//
//   void updateCalendar() {
//     // 캘린더 업데이트 로직 구현
//     // 예를 들어, 선택된 날짜를 기준으로 일정을 다시 가져오는 등의 작업 수행
//     _fetchEvents();
//   }
//
//   Future<void> _fetchEvents() async {
//     final events = await getEventsForDate(selectedDate);
//     final resultEvents = await getResultEventsForDate(selectedDate);
//
//     print('Fetched events: $events');
//     print('Fetched result events: $resultEvents');
//
//     setState(() {
//       scheduleData[formattedDate] = List.generate(timeList.length, (index) {
//         final eventTimeStart = DateTime(
//           selectedDate.year,
//           selectedDate.month,
//           selectedDate.day,
//           startTime + index,
//         );
//         final eventTimeEnd = eventTimeStart.add(Duration(hours: 1));
//
//         final eventsForTime = events
//             .where((event) =>
//         event.eventSttTime != null &&
//             event.eventEndTime != null &&
//             eventTimeStart.isBefore(event.eventEndTime!) &&
//             eventTimeEnd.isAfter(event.eventSttTime!))
//             .toList();
//
//         final resultEventsForTime = resultEvents.where((resultEvent) {
//           try {
//             final retSttTime = resultEvent.eventResultSttTime;
//             final retEndTime = resultEvent.eventResultEndTime;
//
//             if (retSttTime != null && retEndTime != null) {
//               return (eventTimeStart.isBefore(retEndTime) ||
//                   eventTimeStart.isAtSameMomentAs(retSttTime)) &&
//                   (eventTimeEnd.isAfter(retSttTime) ||
//                       eventTimeEnd.isAtSameMomentAs(retEndTime));
//             }
//             return false;
//           } catch (e) {
//             print('Invalid date format in result event: $e');
//             return false;
//           }
//         }).toList();
//
//         print('Events for time $eventTimeStart: $eventsForTime');
//         print('Result events for time $eventTimeStart: $resultEventsForTime');
//
//         final eventForTime =
//         eventsForTime.isNotEmpty ? eventsForTime.first : null;
//
//         final resultEventForTime =
//         resultEventsForTime.isNotEmpty ? resultEventsForTime.first : null;
//
//         return {
//           'plan': eventForTime?.eventTitle ?? '',
//           'actual': resultEventForTime?.eventResultTitle ?? '',
//         };
//       });
//       print('Updated schedule data: $scheduleData');
//       selectedStates = List.generate(timeList.length, (index) => false);
//     });
//   }
//
//   void _updateDate(int daysOffset) {
//     selectedDate = selectedDate.add(Duration(days: daysOffset));
//     formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//     _initScheduleList();
//     _fetchEvents();
//     selectedStates = List.generate(24, (index) => false);
//   }
//
//   Future<List<EventResultModel>> getResultEventsForDate(DateTime date) async {
//     try {
//       // 시작과 끝 시간을 정의합니다.
//       final startOfDay = DateTime(date.year, date.month, date.day);
//       final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
//
//       // 날짜를 ISO 8601 형식의 문자열로 변환합니다.
//       final startOfDayStr = startOfDay.toIso8601String();
//       final endOfDayStr = endOfDay.toIso8601String();
//
//       final QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('result_events')
//           .where('eventResultDate', isGreaterThanOrEqualTo: startOfDayStr)
//           .where('eventResultDate', isLessThanOrEqualTo: endOfDayStr)
//           .get();
//
//       final List<EventResultModel> resultEvents = snapshot.docs
//           .map((doc) =>
//           EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//       return resultEvents;
//     } catch (e) {
//       print('Error fetching events: $e');
//       return [];
//     }
//
//     //   // 결과 이벤트 가져오기
//     //   try {
//     //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
//     //         .collection('result_events')
//     //         .where('eventRetDate',
//     //         isGreaterThanOrEqualTo:
//     //         DateTime(date.year, date.month, date.day).toIso8601String())
//     //         .where('eventRetDate',
//     //         isLessThan: DateTime(date.year, date.month, date.day)
//     //             .add(Duration(days: 1))
//     //             .toIso8601String())
//     //         .get();
//     //
//     //     final List<EventResultModel> resultEvents = snapshot.docs
//     //         .map((doc) =>
//     //         EventResultModel.fromMap(doc.data() as Map<String, dynamic>))
//     //         .toList();
//     //
//     //     return resultEvents;
//     //   } catch (e) {
//     //     print('Error fetching result events: $e');
//     //     return [];
//     //   }
//     // }
//   }
//
//   List<String> get timeList =>
//       List.generate(endTime - startTime + 1, (index) {
//         int hour = startTime + index;
//         return '${hour.toString().padLeft(2, '0')}:00';
//       });
//
//   List<Map<String, String>> get scheduleList =>
//       List.generate(endTime - startTime + 1, (_) => {'plan': '', 'actual': ''});
//
//   // Future<List<EventModel>> getEventsForDate(DateTime date) async {
//   //   try {
//   //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
//   //         .collection('events')
//   //         .where('eventDate', isEqualTo: DateFormat('yyyy-MM-dd').format(date))
//   //         .get();
//   //
//   //     final List<EventModel> events = snapshot.docs
//   //         .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
//   //         .toList();
//   //
//   //     // final QuerySnapshot recurringSnapshot = await FirebaseFirestore.instance
//   //     //     .collection('events')
//   //     //     .where('isRecurring', isEqualTo: true)
//   //     //     .get();
//   //     //
//   //     // final List<EventModel> recurringEvents = recurringSnapshot.docs
//   //     //     .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
//   //     //     .where((event) {
//   //     //   final eventDate = event.eventDate;
//   //     //   if (eventDate == null) return false;
//   //     //   final eventDateTime = DateTime(
//   //     //       eventDate.year, eventDate.month, eventDate.day);
//   //     //   final difference = date
//   //     //       .difference(eventDateTime)
//   //     //       .inDays;
//   //     //   return difference >= 0 && difference % 7 == 0;
//   //     // })
//   //     //     .toList();
//   //     //
//   //     // final List<EventModel> allEvents = [];
//   //     // allEvents.addAll(events);
//   //     // allEvents.addAll(recurringEvents);
//   //     //
//   //     // final Map<String, EventModel> eventMap = {};
//   //     // for (final event in allEvents) {
//   //     //   final key = '${event.eventTitle}_${event.eventSttTime}';
//   //     //   if (!eventMap.containsKey(key)) {
//   //     //     eventMap[key] = event;
//   //     //   }
//   //     // }
//   //     //
//   //     // return eventMap.values.toList();
//   //     return events;
//   //   } catch (e) {
//   //     print('Error fetching events: $e');
//   //     return [];
//   //   }
//   // }
//
//   Future<List<EventModel>> getEventsForDate(DateTime date) async {
//     try {
//       // 시작과 끝 시간을 정의합니다.
//       final startOfDay = DateTime(date.year, date.month, date.day);
//       final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
//
//       // 날짜를 ISO 8601 형식의 문자열로 변환합니다.
//       final startOfDayStr = startOfDay.toIso8601String();
//       final endOfDayStr = endOfDay.toIso8601String();
//
//       final QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('events')
//           .where('eventDate', isGreaterThanOrEqualTo: startOfDayStr)
//           .where('eventDate', isLessThanOrEqualTo: endOfDayStr)
//           .get();
//
//       final List<EventModel> events = snapshot.docs
//           .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//       return events;
//     } catch (e) {
//       print('Error fetching events: $e');
//       return [];
//     }
//   }
//
//   void _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//         _fetchEvents();
//       });
//     }
//   }
//
//   Future<void> _updateEvent_plan(EventModel event, int index) async {
//     await _updateEvent(context, 'events', event, index);
//   }
//
//   Future<void> _deleteEvent_plan(EventModel event) async {
//     await _deleteEvent('events', event.eventId);
//   }
//
//   Future<void> _deleteEvent_actual(EventResultModel event) async {
//     await _deleteEvent('result_events', event.eventResultId);
//   }
//
//   Future<void> _updateEvent_actual(EventResultModel event, int index) async {
//     await _updateEvent(context, 'result_events', event, index);
//   }
//
//   void _initScheduleList() {
//     String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//     if (scheduleData[formattedDate] == null) {
//       scheduleData[formattedDate] = List.generate(
//         endTime - startTime + 1,
//             (_) => {'plan': '', 'actual': ''},
//       );
//     }
//   }
//
//   Future<void> _deleteEvent(String collectionName, String eventId) async {
//     // 이벤트 삭제 메서드
//     try {
//       await FirebaseFirestore.instance
//           .collection(collectionName)
//           .doc(eventId)
//           .delete();
//       _fetchEvents();
//     } catch (e) {
//       print('Error deleting event: $e');
//       // 예외 처리 로직 추가 (예: 사용자에게 에러 메시지 표시)
//     }
//   }
//
//   Future<void> _updateEvent(BuildContext context, // 이벤트 업데이트 메서드
//       String collectionName,
//       dynamic event,
//       int index,) async {
//     try {
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) =>
//               AddEventScreen(
//                 selectedDate: event.eventDate ??
//                     DateTime.parse(event.eventRetDate),
//                 selectedTime:
//                 event.eventSttTime ?? DateTime.parse(event.eventRetSttTime),
//                 event: event is EventModel ? event : null,
//                 actualevent: event is EventResultModel ? event : null,
//                 isFinalEvent: collectionName == 'result_events',
//               ),
//         ),
//       );
//
//       if (result != null) {
//         setState(() {
//           if (collectionName == 'events') {
//             scheduleData[formattedDate]?[index]['plan'] =
//                 (result as EventModel).eventTitle;
//           } else {
//             scheduleData[formattedDate]?[index]['actual'] =
//                 (result as EventResultModel).eventResultTitle;
//           }
//         });
//       }
//     } catch (e) {
//       print('Error updating event: $e');
//       // 예외 처리 로직 추가 (예: 사용자에게 에러 메시지 표시)
//     }
//   }
//
//   // // 예시 사용법
//   // await _deleteEvent('events', event.eventId);
//   // await _deleteEvent('result_events', eventResult.eventRetId);
//   //
//   // await _updateEvent(context, 'events', event, index);
//   // await _updateEvent(context, 'result_events', eventResult, index);
//
//   void _copyEventToResult(int index) async {
//     final planTitle = scheduleData[formattedDate]?[index]['plan'];
//     if (planTitle != null && planTitle.isNotEmpty) {
//       final eventDate = DateTime.parse(formattedDate);
//       final eventStartTime = DateTime(
//           eventDate.year, eventDate.month, eventDate.day, startTime + index);
//
//
//       final eventSnapshot = await FirebaseFirestore.instance
//           .collection('events')
//           .where('eventDate', isEqualTo: eventDate.toIso8601String())
//           .where('eventTitle', isEqualTo: planTitle)
//           .get();
//
//       if (eventSnapshot.docs.isNotEmpty) {
//         final eventData = eventSnapshot.docs.first.data();
//         final event = EventModel.fromMap(eventData);
//
//         final eventResult = EventResultModel(
//           eventResultId:
//           FirebaseFirestore.instance
//               .collection('result_events')
//               .doc()
//               .id,
//           eventId: event.eventId,
//           categoryId: event.categoryId,
//           userId: event.userId,
//           eventResultDate: eventDate,
//           eventResultSttTime: event.eventSttTime,
//           eventResultEndTime: event.eventEndTime,
//           eventResultTitle: event.eventTitle,
//           eventResultContent: event.eventContent,
//           allDayYn: event.allDayYn,
//           // allDayYn 추가
//           completeYn: 'Y',
//         );
//
//         // 문서가 추가된 후 ID를 가져와서 실제 일정을 업데이트합니다.
//         await FirebaseFirestore.instance
//             .collection('result_events')
//             .doc(eventResult.eventResultId)
//             .set(eventResult.toMap());
//
//         setState(() {
//           scheduleData[formattedDate]?[index]['actual'] =
//               eventResult.eventResultTitle;
//         });
//
//         _fetchEvents();
//       }
//     }
//     _toggleCheckbox(index);
//   }
//
//
//
//
//
//
//   Future<void> _loadCheckboxStates() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       selectedStates = List.generate(
//           24, (index) => prefs.getBool('checkbox_$index') ?? false);
//     });
//   }
//
//   void _addResultEvent(int index) async {
//     final eventTitle = scheduleData[formattedDate]?[index]['plan'] ?? '';
//     final eventDate = DateTime.parse(formattedDate);
//     final eventStartTime = DateTime(
//         eventDate.year, eventDate.month, eventDate.day, startTime + index);
//
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddEventScreen(
//           selectedDate: eventDate,
//           selectedTime: eventStartTime,
//           isFinalEvent: true,
//           eventTitle: eventTitle,
//         ),
//       ),
//     );
//
//     if (result != null && result is EventResultModel) {
//       final docRef = await FirebaseFirestore.instance
//           .collection('result_events')
//           .add(result.toMap());
//
//       // 문서가 추가된 후 ID를 가져와서 실제 일정을 업데이트합니다.
//       await FirebaseFirestore.instance
//           .collection('result_events')
//           .doc(docRef.id)
//           .update({'eventRetId': docRef.id});
//
//       setState(() {
//         scheduleData[formattedDate]?[index]['actual'] = result.eventResultTitle;
//       });
//       _fetchEvents();
//     }
//   }
//
//   void _toggleCheckbox(int index) {
//     setState(() {
//       selectedStates[index] = !selectedStates[index];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double planColumnWidth = screenWidth * 0.3;
//     double actualColumnWidth = screenWidth * 0.3;
//     double timeColumnWidth = screenWidth * 0.15;
//     double adjustColumnWidth = screenWidth * 0.1;
//     String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: InkWell(
//           onTap: () => _selectDate(context),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.arrow_left),
//                 onPressed: () {
//                   _updateDate(-1);
//                   _fetchEvents();
//                 },
//               ),
//               Text(formattedDate),
//               IconButton(
//                 icon: Icon(Icons.arrow_right),
//                 onPressed: () {
//                   _updateDate(1);
//                   _fetchEvents();
//                 },
//               ),
//             ],
//           ),
//         ),
//         // actions: [
//         //   IconButton(
//         //     icon: Icon(Icons.settings),
//         //     onPressed: () {
//         //       Navigator.of(context).push(
//         //         MaterialPageRoute(
//         //           builder: (context) =>
//         //               SettingsScreen(
//         //                 onTimeRangeChanged: (start, end) {
//         //                   setState(() {
//         //                     startTime = start;
//         //                     endTime = end;
//         //                     _initScheduleList();
//         //                   });
//         //                 },
//         //                 initialStartTime: startTime,
//         //                 initialEndTime: endTime,
//         //               ),
//         //         ),
//         //       );
//         //     },
//         //   ),
//         // ],
//       ),
//       body: SingleChildScrollView(
//         child: DataTable(
//           columnSpacing: 10,
//           columns: [
//             DataColumn(
//               label: Container(
//                 width: adjustColumnWidth,
//                 child: Text(''),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 width: timeColumnWidth,
//                 child: Text('시간'),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 width: planColumnWidth,
//                 child: Text('일정'),
//               ),
//             ),
//             DataColumn(
//               label: Container(
//                 width: actualColumnWidth,
//                 child: Text('결과'),
//               ),
//             ),
//           ],
//           rows: List.generate(
//             timeList.length,
//             (index) => DataRow(cells: [
//               DataCell(
//                 Row(children: [
//                   IconButton(
//                     icon: Icon(
//                       selectedStates[index]
//                           ? Icons.check_box
//                           : Icons.check_box_outline_blank,
//                     ),
//                     onPressed: () {
//                       _toggleCheckbox(index);
//                       _copyEventToResult(index);
//                     },
//                   ),
//                 ]),
//               ),
//               DataCell(
//                 Container(
//                   width: timeColumnWidth,
//                   child: Text(
//                     timeList[index],
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//               DataCell(
//                 Container(
//                   width: planColumnWidth,
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           scheduleData[formattedDate]?[index]['plan'] ?? '',
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 onTap: () async {
//                   final eventTitle =
//                       scheduleData[formattedDate]?[index]['plan'];
//                   if (eventTitle == null || eventTitle.isEmpty) {
//                     DateTime selectedDate = DateTime.parse(formattedDate);
//
//                     DateTime selectedDateTime = DateTime(
//                       selectedDate.year,
//                       selectedDate.month,
//                       selectedDate.day,
//                       startTime + index,
//                       0,
//                     );
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => AddEventScreen(
//                           selectedDate: selectedDate,
//                           selectedTime: selectedDateTime,
//                         ),
//                       ),
//                     );
//                   } else {
//                     final eventDate = DateTime.parse(formattedDate);
//                     final eventStartTime = DateTime(eventDate.year,
//                         eventDate.month, eventDate.day, startTime + index);
//
//                     // Firestore에서 이벤트 데이터 가져오기
//                     final snapshot = await FirebaseFirestore.instance
//                         .collection('events')
//                         .where('eventDate',
//                             isEqualTo: eventDate.toIso8601String())
//                         .where('eventTitle', isEqualTo: eventTitle)
//                         .get();
//
//                     if (snapshot.docs.isNotEmpty) {
//                       final eventData = snapshot.docs.first.data();
//                       final event = EventModel.fromMap(eventData);
//
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => EventDetailScreen(
//                             updateCalendar: updateCalendar,
//                             selectedDate: selectedDate,
//                             event: event,
//                             onEventDeleted: (deleteAllRecurrences) async {
//                               if (deleteAllRecurrences) {
//                                 final snapshot = await FirebaseFirestore
//                                     .instance
//                                     .collection('events')
//                                     .where('eventTitle',
//                                         isEqualTo: event.eventTitle)
//                                     .where('isRecurring', isEqualTo: true)
//                                     .get();
//                                 final batch =
//                                     FirebaseFirestore.instance.batch();
//                                 for (final doc in snapshot.docs) {
//                                   batch.delete(doc.reference);
//                                 }
//                                 await batch.commit();
//                               } else {
//                                 await _updateEvent_plan(event, index);
//                               }
//                               _fetchEvents();
//                             },
//                             onEventEdited: (editedEvent) async {
//                               if (editedEvent != null) {
//                                 await FirebaseFirestore.instance
//                                     .collection('events')
//                                     .doc(event.eventId)
//                                     .update(editedEvent.toMap());
//                               }
//                             },
//                             onEventResultEdited: (editedEventResult) async {
//                               if (editedEventResult != null) {
//                                 await FirebaseFirestore.instance
//                                     .collection('result_events')
//                                     .doc(editedEventResult.eventResultId)
//                                     .update(editedEventResult.toMap());
//                               }
//                             },
//                           ),
//                         ),
//                       );
//                     }
//                   }
//                 },
//               ),
//               DataCell(
//                 Container(
//                   width: actualColumnWidth,
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           scheduleData[formattedDate]?[index]['actual'] ?? '',
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 onTap: () async {
//                   final eventTitle =
//                       scheduleData[formattedDate]?[index]['actual'];
//                   final planTitle =
//                       scheduleData[formattedDate]?[index]['plan'] == eventTitle;
//
//                   if (eventTitle == null || eventTitle.isEmpty) {
//                     if (planTitle != null && planTitle is String && planTitle.isNotEmpty) {
//                       // 계획된 일정이 있지만 결과가 없는 경우
//                       _copyEventToResult(index);
//                     } else {
//                       // 계획된 일정도 없고 결과도 없는 경우
//                       _addResultEvent(index);
//                     }
//                   } else {
//                     final eventDate = DateTime.parse(formattedDate);
//                     final eventSttTime = DateTime(eventDate.year,
//                         eventDate.month, eventDate.day, startTime + index);
//
//                     // Firestore에서 실제 이벤트 데이터 가져오기
//                     final snapshot = await FirebaseFirestore.instance
//                         .collection('result_events')
//                         .where('eventResultDate',
//                             isEqualTo: eventDate.toIso8601String())
//                         .where('eventResultTitle', isEqualTo: eventTitle)
//                         .get();
//
//                     if (snapshot.docs.isNotEmpty) {
//                       final eventData = snapshot.docs.first.data();
//                       final eventResult = EventResultModel.fromMap(eventData);
//
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => EventDetailScreen(
//                             eventResult: eventResult,
//                             selectedDate: selectedDate,
//                             updateCalendar: updateCalendar,
//                             onEventDeleted: (deleteAllRecurrences) async {
//                               await _deleteEvent_actual(eventResult);
//                               _fetchEvents();
//                             },
//                             onEventEdited: (editedEvent) async {},
//                             onEventResultEdited: (editedEventResult) async {
//                               if (editedEventResult != null) {
//                                 await FirebaseFirestore.instance
//                                     .collection('result_events')
//                                     .doc(editedEventResult.eventResultId)
//                                     .update(editedEventResult.toMap());
//                                 _fetchEvents();
//                               }
//                             },
//                           ),
//                         ),
//                       );
//                     }
//                   }
//                 },
//               ),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }
// }ime;
//   final int initialEndTime;
//
//   SettingsScreen({
//     required this.onTimeRangeChanged,
//     required this.initialStartTime,
//     required this.initialEndTime,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // 시작 시간과 종료 시간을 상태로 관리
//
//     int startTime = initialStartTime;
//     int endTime = initialEndTime;
//
//     return Scaffold(
//       appBar: AppBar(title: Text('설정')),
//       body: Column(
//         children: [
//           _buildTimeDropdown(
//             // 시작 시간 드롭다운 버튼
//             context,
//             startTime,
//             endTime,
//                 (value) {
//               if (value != null) {
//                 startTime = value;
//                 if (endTime < startTime) {
//                   endTime = startTime;
//                 }
//               }
//             },
//           ),
//           _buildTimeDropdown(
//             // 종료 시간 드롭다운 버튼
//             context,
//             endTime,
//             24,
//                 (value) {
//               if (value != null) {
//                 endTime = value;
//               }
//             },
//             startTime: startTime,
//           ),
//           ElevatedButton(
//             onPressed: () {
//               onTimeRangeChanged(startTime, endTime);
//               Navigator.of(context).pop();
//             },
//             child: Text('저장'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeDropdown(// 시간 드롭다운 버튼 위젯
//       BuildContext context,
//       int selectedTime,
//       int endTime,
//       ValueChanged<int?> onChanged, {
//         int startTime = 0,
//       }) {
//     return DropdownButton<int>(
//       value: selectedTime,
//       onChanged: onChanged,
//       items: List.generate(endTime - startTime + 1, (index) {
//         int time = startTime + index;
//         return DropdownMenuItem<int>(
//           value: time,
//           child: Text('${time.toString().padLeft(2, '0')}:00'),
//         );
//       }),
//     );
//   }
// }
