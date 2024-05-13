import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/event_model.dart';
import 'addeventscreen.dart';


class CalendarScreen extends StatefulWidget {

  @override
  _CalendarScreenstate createState() => _CalendarScreenstate();
}

Map<DateTime, List<EventModel>> kEvents = {};

class _CalendarScreenstate extends State<CalendarScreen> {
  Map<DateTime, List<EventModel>> selectedEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<EventModel>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier<List<EventModel>>([]);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }




  List<EventModel> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime.utc(day.year, day.month, day.day);
    List<EventModel> events = kEvents[dateKey] ?? [];
    return events;
  }

  Widget _buildEventsMarker(DateTime date, List<EventModel> events) {
    if (events.isEmpty) return Container();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Container(
          child: Text(
            events[index].eventTitle,
            style: TextStyle(color: Colors.black, fontSize: 10),
          ),
        );
      },
    );
  }

  void _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
    setState(() {
      kEvents = _groupEvents(events);
    });
  }

  Map<DateTime, List<EventModel>> _groupEvents(List<EventModel> events) {
    final groupedEvents = <DateTime, List<EventModel>>{};
    for (final event in events) {
      final date = DateTime.utc(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      if (groupedEvents[date] == null) {
        groupedEvents[date] = [];
      }
      groupedEvents[date]!.add(event);
    }
    return groupedEvents;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
    if (_getEventsForDay(selectedDay).isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DayEventsScreen(
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


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rowHeight =
        (size.height - kToolbarHeight - MediaQuery.of(context).padding.top) / 7;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar<EventModel>(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rowHeight: rowHeight,
                daysOfWeekHeight: rowHeight / 2,
                eventLoader: _getEventsForDay,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    return _buildEventsMarker(date, events);
                  },
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
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {},
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
      ),
    );
  }
}

class DayEventsScreen extends StatefulWidget {
  final List<EventModel> events;
  final DateTime selectedDate;
  final VoidCallback updateCalendar;
  final bool deleteAllRecurrences = false;

  DayEventsScreen({
    required this.events,
    required this.selectedDate,
    required this.updateCalendar,

  });

  @override
  _DayEventsScreenState createState() => _DayEventsScreenState();
}

class _DayEventsScreenState extends State<DayEventsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void didUpdateWidget(covariant DayEventsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _fetchEvents();
    }
  }

  void _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
    setState(() {
      widget.events
        ..clear()
        ..addAll(events.where((event) =>
            isSameDay(event.eventDate, widget.selectedDate)));
    });
    widget.updateCalendar();
  }


 Future<void> _deleteEvent(EventModel event) async {
    // 파이어베이스에서 일정 삭제
    await FirebaseFirestore.instance.collection('events').doc(event.eventId).delete();
    _fetchEvents(); // 일정 목록 갱신
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title:
        Text("${widget.selectedDate.toString().split(' ')[0]} 일정"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: widget.events.length,
        itemBuilder: (context, index) {
          final event = widget.events[index];
          return ListTile(
            title: Text(event.eventTitle),
            subtitle: Text(DateFormat('HH:mm').format(event.eventSttTime)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(
                    event: event,
                    onEventDeleted: (deleteAllRecurrences) async {
                      if (deleteAllRecurrences) {
                        // 반복 일정의 모든 항목을 삭제
                        final snapshot = await FirebaseFirestore.instance
                            .collection('events')
                            .where('eventId', isEqualTo: event.eventId)
                            .where('isRecurring', isEqualTo: true)
                            .get();
                        final batch = FirebaseFirestore.instance.batch();
                        for (final doc in snapshot.docs) {
                          batch.delete(doc.reference);
                        }
                        await batch.commit();
                      } else {
                        await _deleteEvent(event);
                      }
                      _fetchEvents(); // 일정 목록 갱신
                    },
                    onEventEdited: (editedEvent) async {
                      await FirebaseFirestore.instance
                          .collection('events')
                          .doc(event.eventId)
                          .update(editedEvent.toMap());
                      _fetchEvents(); // 일정 목록 갱신
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEventScreen(selectedDate: widget.selectedDate)),
        );
        _fetchEvents(); // 일정 목록 갱신
      },

        child: Icon(Icons.add),
      ),
    );
  }
}



class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final Function(bool deleteAllRecurrence) onEventDeleted;
  final Function(EventModel) onEventEdited;

  EventDetailScreen({
    required this.event,
    required this.onEventDeleted,
    required this.onEventEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 세부사항'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final editedEvent = await Navigator.push<EventModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventScreen(
                    selectedDate: event.eventDate,
                    event: event,
                  ),
                ),
              );
              if (editedEvent != null) {
                onEventEdited(editedEvent);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              if (event.isRecurring) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('반복 일정 삭제'),
                    content: Text('이 일정의 모든 반복 항목을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          onEventDeleted(true);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('삭제'),
                      ),
                      TextButton(
                        onPressed: () {
                          onEventDeleted(false);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('이 이항목만 삭제'),
                      ),
                    ],
                  ),
                );
              } else {
                onEventDeleted(false);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.eventTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '날짜: ${event.eventDate.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              '일정 추가 시간: ${DateFormat('HH:mm').format(event.eventSttTime)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              '세부사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              event.eventContent,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),

      ),
    );
  }
}

