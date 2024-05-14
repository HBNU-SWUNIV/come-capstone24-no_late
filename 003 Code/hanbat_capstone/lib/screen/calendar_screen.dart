import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';
import 'add_event_screen.dart';


class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

Map<DateTime, List<EventModel>> kEvents = {};

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<EventModel>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier<List<EventModel>>([]);
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _fetchEvents() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('events').get();
    final events =
        snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
    setState(() {
      kEvents = _groupEvents(events);
    });
  }

  Map<DateTime, List<EventModel>> _groupEvents(List<EventModel> events) {
    final groupedEvents = <DateTime, List<EventModel>>{};
    for (final event in events) {
      final date = DateTime.utc(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);
      groupedEvents.putIfAbsent(date, () => []).add(event);
    }
    return groupedEvents;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

  Widget _buildEventsMarker(DateTime date, List<EventModel> events) {
    if (events.isEmpty) return SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Text(
          events[index].eventTitle,
          style: TextStyle(color: Colors.black, fontSize: 10),
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents.value = _getEventsForDay(selectedDay);
    });

    // 선택한 날짜의 이벤트를 가져와서 DayEventsScreen으로 이동
    final selectedEvents = _getEventsForDay(selectedDay);

    if (selectedEvents.isEmpty) {
      // 일정이 없는 경우, 일정 추가 화면으로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEventScreen(selectedDate: selectedDay),
        ),
      );
      if (result != null) {
        // 일정 추가 후 캘린더 갱신
        _fetchEvents();
      }
    } else {
      // 일정이 있는 경우, 스케줄러 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RootScreen( selectedDate: selectedDay),
        ),
      );
    };

  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rowHeight =
        (size.height - kToolbarHeight - MediaQuery.of(context).padding.top) / 7;

    return Scaffold(
      body: Column(
        children: [
          TableCalendar<EventModel>(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            rowHeight: rowHeight,
            daysOfWeekHeight: rowHeight / 7,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) =>
                  _buildEventsMarker(date, events),
              defaultBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
              selectedBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
              todayBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
              outsideBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ],
      ),
    );
  }
}
