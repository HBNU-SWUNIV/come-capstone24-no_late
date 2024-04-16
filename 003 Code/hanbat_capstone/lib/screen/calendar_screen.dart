
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'add_event_screen.dart';
import 'day_events_page.dart';
import 'event.dart';



class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

Map<DateTime, List<Event>> kEvents = {

};




class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Event>> selectedEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<Event>> _selectedEvents;  // ValueNotifier 초기화

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier<List<Event>>([]);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    DateTime dateKey = DateTime.utc(day.year, day.month, day.day);
    var events = kEvents[dateKey] ?? [];

    return events;
  }

  Widget _buildEventMarker(DateTime date, List<Event> events) {
    if (events.isNotEmpty) {
      // 일정이 있는 날짜에 마커 표시
      print("Building marker for $date with events: $events");
      return Positioned(
        right: 1,
        bottom: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
          width: 16.0,
          height: 16.0,
          child: Center(
            child: Text(
              '${events.length}',
              style: TextStyle().copyWith(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      );
    }
    return Container();
  }


  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
    if (_selectedEvents.value.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DayEventsPage(
            events: _selectedEvents.value,
            selectedDate: selectedDay,
            updateCalendar: _updateCalendar,
          ),
        ),
      );
    }
  }
  void _updateCalendar() {
    setState(() {
      _focusedDay = _focusedDay;
    });
  }

  void _openAddEventPage() async {
    final newEvent = await Navigator.push<Event>(
        context,
        MaterialPageRoute(builder: (context) => AddEventPage())
    );

    if (newEvent != null) {
      setState(() {
        DateTime eventDate = DateTime.utc(newEvent.date.year, newEvent.date.month, newEvent.date.day);
        List<Event> events = kEvents[eventDate] ?? [];

        // Check if an event with the same title and time already exists
        bool eventExists = events.any((event) =>
        event.title == newEvent.title && event.time == newEvent.time);

        if (!eventExists) {
          // If the event doesn't exist, add it to the list
          kEvents[eventDate] = [...events, newEvent];
        }
      });
    }
  }






  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top; // 상태 바 높이
    final availableHeight = screenHeight  - statusBarHeight;
    final rowHeight = availableHeight / 7;

    return Scaffold(

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEventPage,
          //
          // if (_selectedDay != null) {
          //   Navigator.of(context).push(MaterialPageRoute(
          //       builder: (context) => AddEventPage()));
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text('날짜를 선택해주세요.'))
          //   );
          // }
        // },
        backgroundColor: Colors.white,
        child: const Icon(
            Icons.add_circle_outline
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar<Event>(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              rowHeight: rowHeight,
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return _buildEventMarker(date, events);
                },
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: _onDaySelected,
                // _showAddEventDialog(selectedDay);

              onFormatChanged: (format) {
                // if (_calendarFormat != format) {
                //   setState(() {
                //     _calendarFormat = format;
                //   });
                // }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
