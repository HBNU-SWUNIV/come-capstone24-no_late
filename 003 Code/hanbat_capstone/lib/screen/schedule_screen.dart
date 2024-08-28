
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

class ScheduleScreen extends StatefulWidget {
  final DateTime? selectedDate;

  ScheduleScreen({this.selectedDate});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime selectedDate;
  late String formattedDate;
  Map<String, List<Map<String, String>>> scheduleData = {};
  int startTime = 0;
  int endTime = 23;
  Map<int, bool> selectedStates = {};
  final EventService eventService = EventService();
  late PageController _pageController;
  int initialPage = 5000;
  List<EventModel> allDayEvents = [];
  List<EventModel> regularEvents = [];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate ?? DateTime.now();
    formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    _loadSettings();
    _pageController = PageController(initialPage: initialPage);
    _fetchEvents();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      startTime = prefs.getInt('startTime') ?? 0;
      endTime = prefs.getInt('endTime') ?? 23;
    });
    _initScheduleList();
    _fetchEvents();
    _loadCheckboxStates();
  }

  void _initScheduleList() {
    if (scheduleData[formattedDate] == null) {
      scheduleData[formattedDate] = List.generate(
        endTime - startTime + 1,
            (_) => {'plan': '', 'actual': ''},
      );
    }
  }


  Future<void> _fetchEvents() async {
    final events = await eventService.getEventsForDate(selectedDate);
    final resultEvents = await eventService.getResultEventsForDate(
        selectedDate);

    setState(() {
      // scheduleData[formattedDate] = eventService.generateScheduleData(
      //     selectedDate, startTime, endTime, events, resultEvents);
      allDayEvents = events.where((event) => event.isAllDay).toList();
      regularEvents = events.where((event) => !event.isAllDay).toList();
      scheduleData[formattedDate] = eventService.generateScheduleData(
          selectedDate, startTime, endTime, regularEvents, resultEvents);
    });
  }

  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
      formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      _initScheduleList();
      _fetchEvents();
      _loadCheckboxStates();
    });
  }

  Future<void> _loadCheckboxStates() async {
    final states = await eventService.loadTimeBasedCheckboxStatesForDate(formattedDate);
    setState(() {
      selectedStates = states;
    });
  }

  void _handleCheckboxChange(int hour) async {
    setState(() {
      selectedStates[hour] = !(selectedStates[hour] ?? false);
    });
    await eventService.saveTimeBasedCheckboxState(formattedDate, hour, selectedStates[hour]!);
    if (selectedStates[hour]!) {
      await eventService.copyEventToResult(formattedDate, hour - startTime, startTime);
      await eventService.updateEventCompletedStatus(formattedDate, hour, 'Y');
    } else {
      await eventService.updateEventCompletedStatus(formattedDate, hour, 'N');
    }
    _fetchEvents();
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
        builder: (context) =>
            AddEventScreen(
              selectedDate: selectedDate,
              selectedTime: DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
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
        builder: (context) =>
            AddEventScreen(
              selectedDate: selectedDate,
              selectedTime: DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
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

    final eventDate = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);

    print("Querying Firestore for event on $eventDate");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(isplan ? 'events' : 'result_events')
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isGreaterThanOrEqualTo: eventDate.toUtc().toIso8601String())
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isLessThan: eventDate.add(Duration(days: 1))
              .toUtc()
              .toIso8601String())
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

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EventDetailScreen(
                    event: isplan ? event as EventModel : null,
                    eventResult: isplan ? null : event as EventResultModel,
                    selectedDate: selectedDate,
                    updateCalendar: _fetchEvents,
                    onEventDeleted: (fasle) async {
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
                        _fetchEvents();
                      }
                    },
                  ),
            ),
          );
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
    return Scaffold(
      appBar: AppBar(
        title: DateSelector(
          selectedDate: selectedDate,
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
              formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
              _initScheduleList();
              _fetchEvents();
              _loadCheckboxStates();
            });
          },
          onPreviousDay: () => _updateDate(-1),
          onNextDay: () => _updateDate(1),
        ),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (pageIndex) {
          int dayDifference = pageIndex - initialPage;
          _updateDate(dayDifference);
          initialPage = pageIndex;
        },
        itemBuilder: (context, index) {
          return Column(
            children: [
              _buildAllDayEventsSection(),
              Expanded(
          child: _buildRegularEventsSection(),
                // child: ListView.builder(
                //   itemCount: endTime - startTime + 1,
                //   itemBuilder: (context, index) {
                //     return _buildTimeBlock(index);
        // }

              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildTimeBlock(int index) {
    final hour = startTime + index;
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
                  Text('${hour.toString().padLeft(2, '0')}:00'),
                  CheckboxComponent(
                    isChecked: selectedStates[hour] ?? false,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _handleCheckboxChange(hour);
                      }
                    },
                    activeColor:  Colors.lightBlue[900],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEventCell(
                scheduleData[formattedDate]?[index]['plan'] ?? '',
                scheduleData[formattedDate]?[index]['planCategoryId'] ?? '',
                    () => _handlePlanCellTap(index),
                Colors.blue.withOpacity(0.1),

              ),
            ),
            Expanded(
              flex: 2,
              child: _buildEventCell(
                scheduleData[formattedDate]?[index]['actual'] ?? '',
                scheduleData[formattedDate]?[index]['actualCategoryId'] ?? '',
                    () => _handleActualCellTap(index),
                Colors.green.withOpacity(0.1),

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCell(String eventTitle, String categoryId, VoidCallback onTap, Color backgroundColor) {
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
  Widget _buildAllDayEventsSection() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '종일 일정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allDayEvents.length,
            itemBuilder: (context, index) {
              final event = allDayEvents[index];
              return ListTile(
                title: Text(event.eventTitle),
                subtitle: Text('종일'),
                onTap: () => _openEventDetail(event.eventTitle, index, isplan: true),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegularEventsSection() {
    return ListView.builder(
      itemCount: endTime - startTime + 1,
      itemBuilder: (context, index) {
        return _buildTimeBlock(index);
      },
    );
  }



}


