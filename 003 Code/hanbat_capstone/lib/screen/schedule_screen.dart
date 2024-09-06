
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import '../component/date_selector.dart';
import '../component/time_cell.dart';
import '../component/event_cell.dart';
import '../component/checkbox_component.dart';
import '../services/event_service.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

class ScheduleScreen extends StatefulWidget {
  final DateTime? selectedDate;

  ScheduleScreen({this.selectedDate});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String formattedDate;
  Map<String, List<Map<String, String>>> scheduleData = {};
  int startTime = 0;
  int endTime = 23;
  Map<int, bool> selectedStates = {};
  Map<String, bool> allDayEventStates = {};
  final EventService eventService = EventService();
  late DateTime _focusedDate;
  late PageController _pageController;
  int _currentPage = 5000;
  List<EventModel> allDayEvents = [];
  List<EventModel> regularEvents = [];
  List<EventResultModel> regularResultEvents = [];
  bool _isLoading = true;
  List<EventResultModel> resultEvents = [];

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate ?? DateTime.now();
    formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
    _loadSettings();
    _pageController = PageController(initialPage: 1000);
    _ensureUserLoggedIn();
    _loadAllDayEventStates();
    _loadEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final allEvents = await eventService.getEventsForDate(_focusedDate);
      final regularResultEvents = await eventService.getResultEventsForDate(_focusedDate, excludeAllDay: true);

      setState(() {
        allDayEvents = allEvents.where((event) => event.isAllDay).toList();
        regularEvents = allEvents.where((event) => !event.isAllDay).toList();
        this.regularResultEvents = regularResultEvents;
        _updateScheduleData();
      });
    } catch (e) {
      print('Error loading events: $e');
      // 에러 처리
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _updateScheduleData() {
    scheduleData[formattedDate] = eventService.generateScheduleData(
      _focusedDate,
      startTime,
      endTime,
      regularEvents,
      regularResultEvents,
    );
  }

  Future<void> _loadAllDayEventStates() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('allDayEventStates')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: formattedDate)
          .get();

      setState(() {
        allDayEventStates = Map.fromEntries(
            snapshot.docs.map((doc) => MapEntry(doc['eventId'] as String, doc['isCompleted'] as bool))
        );
      });
    } catch (e) {
      print('Error loading all-day event states: $e');
    }
  }

  Future<void> _saveAllDayEventState(String eventId, bool isCompleted) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('allDayEventStates')
          .doc('${userId}_${formattedDate}_$eventId')
          .set({
        'userId': userId,
        'date': formattedDate,
        'eventId': eventId,
        'isCompleted': isCompleted,
      });
    } catch (e) {
      print('Error saving all-day event state: $e');
    }
  }

  Future<void> _handleAllDayEventCheckboxChange(String eventId, bool newValue) async {
    try {
      await eventService.updateAllDayEventState(formattedDate, eventId, newValue);
      setState(() {
        allDayEventStates[eventId] = newValue;
      });



      // 상태 변경 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? '종일 일정이 완료되었습니다.'
              : '종일 일정 완료가 취소되었습니다.'),
        ),
      );




    } catch (e) {
      print('Error handling all-day event checkbox change: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('종일 일정 상태 변경 중 오류가 발생했습니다.')),
      );
      setState(() {
        allDayEventStates[eventId] = !newValue;
      });
    }
  }

  Widget _buildAllDayEventsSection() {
    if (allDayEvents.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allDayEvents.length,
            itemBuilder: (context, index) {
              final event = allDayEvents[index];
              final isCompleted = allDayEventStates[event.eventId] ?? false;
              return GestureDetector(
                onTap: () => _handleAllDayEventTap(event),
                onDoubleTap: () => _openEventDetail(event.eventTitle, index, isplan: true),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.eventTitle,
                          style: TextStyle(
                            // 변경: 완료된 일정에 취소선 추가
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      // 추가: 완료된 일정에 체크 아이콘 표시
                      if (isCompleted)
                        Icon(Icons.check, color: Colors.green),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAllDayEventTap(EventModel event) async {
    final newState = !(allDayEventStates[event.eventId] ?? false);
    setState(() {
      allDayEventStates[event.eventId] = newState;
    });
    await _saveAllDayEventState(event.eventId, newState);
    await _handleAllDayEventCheckboxChange(event.eventId, newState);
  }



  Future<void> _ensureUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 로그인 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      eventService.setUserId(user.uid);
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        startTime = prefs.getInt('startTime') ?? 0;
        endTime = prefs.getInt('endTime') ?? 23;
      });
      _initScheduleList();
      await _fetchEvents();
      await _loadCheckboxStates();
    } catch (e) {
      print('Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정을 불러오는 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initScheduleList() {
    if (scheduleData[formattedDate] == null) {
      scheduleData[formattedDate] = List.generate(
        endTime - startTime + 1,
            (_) => {'plan': '', 'actual': ''},
      );
    }
  }

// 이 import 문을 파일 상단에 추가해주세요.
//
//   Future<void> _fetchEvents() async {
//     setState(() => _isLoading = true);
//     try {
//       print("Fetching events for date: ${_focusedDate.toIso8601String()}");
//       final events = await eventService.getEventsForDate(_focusedDate);
//       var resultEvents = await eventService.getResultEventsForDate(_focusedDate);
//       final fetchedResultEvents = await eventService.getResultEventsForDate(_focusedDate);
//       print("Fetched ${events.length} events and ${resultEvents.length} result events");
//
//       setState(() {
//         allDayEvents = events.where((event) => event.isAllDay).toList();
//         regularEvents = events.where((event) => !event.isAllDay).toList();
//         resultEvents = fetchedResultEvents;
//         scheduleData[formattedDate] = List.generate(
//           endTime - startTime + 1,
//               (index) {
//             final hour = startTime + index;
//             final planEvents = regularEvents.where((event) {
//               return event.eventSttTime!.hour <= hour && event.eventEndTime!.hour > hour;
//             }).toList();
//             final actualEvents = resultEvents.where((event) {
//               return event.eventResultSttTime!.hour <= hour && event.eventResultEndTime!.hour > hour;
//             }).toList();
//
//             return {
//               'plan': planEvents.isNotEmpty ? planEvents.first.eventTitle : '',
//               'planCategoryId': planEvents.isNotEmpty ? planEvents.first.categoryId : '',
//               'actual': actualEvents.isNotEmpty ? actualEvents.first.eventResultTitle : '',
//               'actualCategoryId': actualEvents.isNotEmpty ? actualEvents.first.categoryId : '',
//               'completedYn': planEvents.isNotEmpty ? planEvents.first.completedYn ?? 'N' : 'N',
//               'eventId': planEvents.isNotEmpty ? planEvents.first.eventId : '',
//             };
//           },
//         );
//
//         // 체크박스 상태 업데이트
//         for (int i = startTime; i <= endTime; i++) {
//           selectedStates[i] = resultEvents.any((event) =>
//           event.eventResultSttTime!.hour <= i && event.eventResultEndTime!.hour > i
//           );
//         }
//       });
//     } catch (e) {
//       print('Error fetching events: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('일정을 불러오는 중 오류가 발생했습니다.')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      print("Fetching events for date: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}");

      final events = await eventService.getEventsForDate(startOfDay);
      final fetchedResultEvents = await eventService.getResultEventsForDate(startOfDay);

      print("Fetched ${events.length} events and ${fetchedResultEvents.length} result events");

      setState(() {
        allDayEvents = events.where((event) => event.isAllDay ?? false).toList();
        regularEvents = events.where((event) => !(event.isAllDay ?? false)).toList();
        resultEvents = fetchedResultEvents;

        allDayEventStates = {
          for (var event in allDayEvents)
            event.eventId: event.completedYn == 'Y'
        };

        scheduleData[formattedDate] = List.generate(
          25,  // 0시부터 24시까지 (25개의 시간대)
              (hour) {
            final planEvents = regularEvents.where((event) {
              if (event.isAllDay ?? false) return false;
              final eventStartHour = event.eventSttTime!.hour;
              final eventEndHour = event.eventEndTime!.hour == 0 ? 24 : event.eventEndTime!.hour;
              return eventStartHour <= hour && hour < eventEndHour;
            }).toList();

            final actualEvents = resultEvents.where((event) {
              if (event.isAllDay ?? false) return false;
              final eventStartHour = event.eventResultSttTime!.hour;
              final eventEndHour = event.eventResultEndTime!.hour == 0 ? 24 : event.eventResultEndTime!.hour;
              return eventStartHour <= hour && hour < eventEndHour;
            }).toList();

            return {
              'plan': planEvents.isNotEmpty ? planEvents.first.eventTitle : '',
              'planCategoryId': planEvents.isNotEmpty ? planEvents.first.categoryId : '',
              'actual': actualEvents.isNotEmpty ? actualEvents.first.eventResultTitle : '',
              'actualCategoryId': actualEvents.isNotEmpty ? actualEvents.first.categoryId : '',
              'completedYn': planEvents.isNotEmpty ? planEvents.first.completedYn ?? 'N' : 'N',
              'eventId': planEvents.isNotEmpty ? planEvents.first.eventId : '',
            };
          },
        );

        for (int hour = 0; hour <= 24; hour++) {
          selectedStates[hour] = resultEvents.any((event) {
            if (event.isAllDay ?? false) return false;
            final eventStartHour = event.eventResultSttTime!.hour;
            final eventEndHour = event.eventResultEndTime!.hour == 0 ? 24 : event.eventResultEndTime!.hour;
            return eventStartHour <= hour && hour < eventEndHour;
          });
        }
      });

      await _loadAllDayEventStates();
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 불러오는 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int page) {
    final newDate = DateTime(_focusedDate.year, _focusedDate.month,
        _focusedDate.day + (page - 1000));
    if (newDate != _focusedDate) {
      setState(() {
        _focusedDate = newDate;
        formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
      });
      _initScheduleList();
      _fetchEvents();
      _loadCheckboxStates();
    }
  }

  void _updateDate(int daysOffset) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: daysOffset));
      formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
      _initScheduleList();
    });
    _fetchEvents();
    _loadCheckboxStates();
  }

  Future<void> _loadCheckboxStates() async {
    final states =
    await eventService.loadTimeBasedCheckboxStatesForDate(formattedDate);
    setState(() {
      selectedStates = states;
    });
  }

  void _handleCheckboxChange(int hour) async {
    print("Checkbox changed for hour: $hour");
    try {
      final eventForHour = regularEvents.firstWhereOrNull((event) {
        final eventEndHour = event.eventEndTime!.hour == 0 ? 24 : event.eventEndTime!.hour;
        return event.eventSttTime!.hour <= hour && eventEndHour > hour;
      });

      if (eventForHour != null) {
        final newState = !(selectedStates[hour] ?? false);
        setState(() {
          selectedStates[hour] = newState;
          if (hour == 23 && eventForHour.eventEndTime!.hour == 0) {
            selectedStates[0] = newState;
          }
        });

        if (newState) {
          print("Moving plan to actual for hour: $hour");
          await eventService.movePlanToActual(formattedDate, hour, eventForHour);
        } else {
          print("Updating result event for hour: $hour");
          await eventService.removeResultEvent(formattedDate, hour, eventForHour.eventId);
        }

        // 상태 업데이트 후 이벤트와 체크박스 상태 다시 로드
        print("Fetching events and loading checkbox states");
        await _fetchEvents();

        // 상태 변경 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newState
                  ? '$hour:00 시간대가 완료되었습니다.'
                  : '$hour:00 시간대 완료가 취소되었습니다.')),
        );
      }
    } catch (e) {
      print('Error handling checkbox change: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 상태 변경 중 오류가 발생했습니다.')),
      );
    }
  }

  void _handlePlanCellTap(int index) async {
    print("Plan cell tapped at index: $index"); // 디버그
    final eventTitle = scheduleData[formattedDate]?[index]['plan'];
    if (eventTitle == null || eventTitle.isEmpty) {
      _addNewEvent(index);
    } else {
      _openEventDetail(eventTitle, index, isplan: true);
    }
  }

  void _handleActualCellTap(int index) async {
    final eventTitle = scheduleData[formattedDate]?[index]['actual'];
    if (eventTitle == null || eventTitle.isEmpty) {
      _addNewResultEvent(index);
    } else {
      _openEventDetail(eventTitle, index, isplan: false);
    }
  }

  void _addNewEvent(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          selectedDate: _focusedDate,
          selectedTime: DateTime(
            _focusedDate.year,
            _focusedDate.month,
            _focusedDate.day,
            startTime + index,
          ),
        ),
      ),
    ).then((_) => _fetchEvents());
  }

  void _addNewResultEvent(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          selectedDate: _focusedDate,
          selectedTime: DateTime(
            _focusedDate.year,
            _focusedDate.month,
            _focusedDate.day,
            startTime + index,
          ),
          isFinalEvent: true,
        ),
      ),
    ).then((_) => _fetchEvents());
  }

  void _openEventDetail(String eventTitle, int index,
      {required bool isplan}) async {
    print("Opening event detail for: $eventTitle, isplan: $isplan");

    final eventDate =
    DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);

    print("Querying Firestore for event on $eventDate");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(isplan ? 'events' : 'result_events')
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isGreaterThanOrEqualTo: eventDate.toUtc().toIso8601String())
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isLessThan:
          eventDate.add(Duration(days: 1)).toUtc().toIso8601String())
          .get();

      print("Firestore query result: ${snapshot.docs.length} documents");

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          print("Found event: ${doc.data()}");
        }

        // 제목이 일치하는 이벤트 찾기
        final matchingEvent = snapshot.docs.firstWhere(
              (doc) =>
          doc.get(isplan ? 'eventTitle' : 'eventResultTitle') == eventTitle,
        );

        if (matchingEvent != null) {
          final event = isplan
              ? EventModel.fromMap(matchingEvent.data())
              : EventResultModel.fromMap(matchingEvent.data());

          print("Matching event found: ${event.toString()}");

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                event: isplan ? event as EventModel : null,
                eventResult: isplan ? null : event as EventResultModel,
                selectedDate: _focusedDate,
                updateCalendar: _fetchEvents,
                onEventDeleted: (deleteAllRecurrence) async {
                  if (isplan) {
                    await eventService.deleteEvent(
                        'events', (event as EventModel).eventId);
                  } else {
                    await eventService.deleteEvent('result_events',
                        (event as EventResultModel).eventResultId);
                  }
                  _fetchEvents();
                },
                onEventEdited: (editedEvent) async {
                  if (editedEvent != null) {
                    await FirebaseFirestore.instance
                        .collection(isplan ? 'events' : 'result_events')
                        .doc(isplan
                        ? (event as EventModel).eventId
                        : (event as EventResultModel).eventResultId)
                        .update(editedEvent.toMap());

                    setState(() {
                      if (isplan) {
                        final updatedEvent = EventModel(
                          eventId: editedEvent.eventId,
                          eventTitle: editedEvent.eventTitle,
                          eventDate: editedEvent.eventDate,
                          eventSttTime: editedEvent.eventSttTime,
                          eventEndTime: editedEvent.eventEndTime,
                          eventContent: editedEvent.eventContent,
                          categoryId: editedEvent.categoryId,
                          userId: editedEvent.userId,
                          isAllDay: editedEvent.isAllDay,
                          completedYn: editedEvent.completedYn,
                          isRecurring: editedEvent.isRecurring,
                          showOnCalendar: editedEvent.showOnCalendar,
                          originalEventId: editedEvent.originalEventId,
                        );
                        // 기존 이벤트를 새로운 이벤트로 교체
                        final eventIndex = regularEvents.indexWhere((e) => e.eventId == updatedEvent.eventId);
                        if (eventIndex != -1) {
                          regularEvents[eventIndex] = updatedEvent;
                        }
                      } else {
                        // EventResultModel에 대한 처리
                      }
                    });
                    _fetchEvents();  // 전체 이벤트 목록 새로고침
                  }
                },
              ),
            ),
          );

          _fetchEvents();
        } else {
          print("No matching event found for title: $eventTitle");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일치하는 이벤트를 찾을 수 없습니다.')),
          );
        }
      } else {
        print("No events found for the given date");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해당 날짜에 이벤트가 없습니다.')),
        );
      }
    } catch (e) {
      print("Error querying Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 조회 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: DateSelector(
          selectedDate: _focusedDate,
          onDateChanged: (date) {
            setState(() {
              _focusedDate = date;
            });
            _fetchEvents();
            _initScheduleList();
            _pageController.jumpToPage(1000); // Reset to the middle page
            _loadCheckboxStates();
          },
          onPreviousDay: () => _pageController.previousPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          onNextDay: () => _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageDate = _focusedDate.add(Duration(days: index - _currentPage));
                return _buildPageContent(pageDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(DateTime pageDate) {
    return Column(
      children: [
        _buildAllDayEventsSection(),
        Expanded(
          child: _buildRegularEventsSection(pageDate),
        ),
      ],
    );
  }

  Widget _buildTimeBlock(int index, DateTime pageDate) {
    final hour = (index);  // 24시를 00시로 처리
    final timeData = scheduleData[formattedDate]?[index];


    // final eventsForThisHour = regularEvents
    //     .where((event) =>
    // !event.isAllDay &&
    //     ((event.eventSttTime?.hour == hour &&
    //         DateFormat('yyyy-MM-dd').format(event.eventDate!) == currentDate) ||
    //         (event.eventEndTime?.hour == hour &&
    //             DateFormat('yyyy-MM-dd').format(event.eventEndTime!) ==
    //                 (hour == 0 ? nextDate : currentDate)))
    // )
    //     .toList();
    // final planEvent = eventsForThisHour.isNotEmpty ? eventsForThisHour.first : null;
    // final actualEvent = resultEvents
    //     .where((event) =>
    // event.eventResultSttTime?.hour == hour &&
    //     DateFormat('yyyy-MM-dd').format(event.eventResultDate!) == currentDate)
    //     .firstOrNull;
    //

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text(hour == 24 ? '24:00' : '${hour.toString().padLeft(2, '0')}:00'),
                  CheckboxComponent(
                    isChecked: selectedStates[hour] ?? false,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _handleCheckboxChange(hour);
                      }
                    },
                    activeColor: Colors.lightBlue[900],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEventCell(
                timeData?['plan'] ?? '',
                timeData?['planCategoryId'] ?? '',
                    () => _handlePlanCellTap(index),
                Colors.blue.withOpacity(0.1),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEventCell(
                timeData?['actual'] ?? '',
                timeData?['actualCategoryId'] ?? '',
                    () => _handleActualCellTap(index),
                Colors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCell(String eventTitle, String categoryId,
      VoidCallback onTap, Color backgroundColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: EventCell(
          eventTitle: eventTitle,
          categoryId: categoryId,
          onTap: onTap,
        ),
      ),
    );
  }

  // Widget _buildAllDayEventsSection() {
  //   if (allDayEvents.isEmpty) {
  //     return SizedBox.shrink(); // 종일 일정이 없으면 이 섹션을 표시하지 않음
  //   }
  //   return Container(
  //     color: Colors.grey[200],
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Text(
  //             '종일 일정',
  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //           ),
  //         ),
  //         ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: allDayEvents.length,
  //           itemBuilder: (context, index) {
  //             final event = allDayEvents[index];
  //             return ListTile(
  //               title: Text(event.eventTitle),
  //               subtitle: Text('종일'),
  //               onTap: () =>
  //                   _openEventDetail(event.eventTitle, index, isplan: true),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRegularEventsSection(DateTime pageDate) {
    return ListView.builder(
      itemCount: 25,  // 24시까지 표시하기 위해 25로 변경
      itemBuilder: (context, index) {
        return _buildTimeBlock(index, pageDate);
      },
    );
  }
}


