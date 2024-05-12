import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CalendarPage extends StatefulWidget {

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

Map<DateTime, List<EventModel>> kEvents = {};

class _CalendarPageState extends State<CalendarPage> {
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

class DayEventsPage extends StatefulWidget {
  final List<EventModel> events;
  final DateTime selectedDate;
  final VoidCallback updateCalendar;
  final bool deleteAllRecurrences = false;

  DayEventsPage({
    required this.events,
    required this.selectedDate,
    required this.updateCalendar,

  });

  @override
  _DayEventsPageState createState() => _DayEventsPageState();
}

class _DayEventsPageState extends State<DayEventsPage> {

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
        Text("Events for ${widget.selectedDate.toString().split(' ')[0]}"),
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
                  builder: (context) => EventDetailsPage(
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
          MaterialPageRoute(builder: (context) => AddEventPage(selectedDate: widget.selectedDate)),
        );
        _fetchEvents(); // 일정 목록 갱신
      },

        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;
  final EventModel? event;

  AddEventPage({this.selectedDate, this.event});
  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  late DateTime? selectedDate;
  late TimeOfDay selectedTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool isRecurring;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    selectedTime = TimeOfDay.fromDateTime(widget.event?.eventSttTime ?? DateTime.now());
    _titleController = TextEditingController(text: widget.event?.eventTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.eventContent ?? '');
    isRecurring = widget.event?.isRecurring ?? false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
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





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      ),
      body: Form(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            if (selectedDate == null)
              ListTile(
                title: Text(
                    "Date: ${selectedDate?.toString().split(' ')[0] ?? 'Select a date'}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
            ListTile(
              title: Text("Time: ${selectedTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
            CheckboxListTile(
              title: Text('Repeat Weekly'),
              value: isRecurring,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    isRecurring = value;
                  });
                }
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null) {
                  final newEvent = EventModel(
                    eventId: '',
                    categoryId: '',
                    userId: '',
                    eventDate: selectedDate!,
                    eventSttTime: DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    eventEndTime: DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    eventTitle: _titleController.text,
                    eventContent: _descriptionController.text,
                    allDayYn: 'N',
                    completeYn: 'N',
                    isRecurring: isRecurring,
                  );
                  final eventRef = await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());
                  final eventId = eventRef.id;
                  await eventRef.update({'eventId': eventId});



                  // 일정 등록 후 이전 화면으로 이동
                  Navigator.pop(context);

                };
                },

              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  final EventModel event;
  final Function(bool deleteAllRecurrence) onEventDeleted;
  final Function(EventModel) onEventEdited;

  EventDetailsPage({
    required this.event,
    required this.onEventDeleted,
    required this.onEventEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final editedEvent = await Navigator.push<EventModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventPage(
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
              'Date: ${event.eventDate.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Time: ${DateFormat('HH:mm').format(event.eventSttTime)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Description:',
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

class EventModel {
  final String eventId;
  final String categoryId;
  final String userId;
  final DateTime eventDate;
  final DateTime eventSttTime;
  final DateTime eventEndTime;
  final String eventTitle;
  final String eventContent;
  final String allDayYn;
  final String completeYn;
  final bool isRecurring;

  EventModel({
    required this.eventId,
    required this.categoryId,
    required this.userId,
    required this.eventDate,
    required this.eventSttTime,
    required this.eventEndTime,
    required this.eventTitle,
    required this.eventContent,
    required this.allDayYn,
    required this.completeYn,
    required this.isRecurring,
  });
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'categoryId': categoryId,
      'userId': userId,
      'eventDate': eventDate.toIso8601String(),
      'eventSttTime': eventSttTime.toIso8601String(),
      'eventEndTime': eventEndTime.toIso8601String(),
      'eventTitle': eventTitle,
      'eventContent': eventContent,
      'allDayYn': allDayYn,
      'completeYn': completeYn,
      'isRecurring':isRecurring,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['eventId'],
      categoryId: map['categoryId'],
      userId: map['userId'],
      eventDate: DateTime.parse(map['eventDate']),
      eventSttTime: DateTime.parse(map['eventSttTime']),
      eventEndTime: DateTime.parse(map['eventEndTime']),
      eventTitle: map['eventTitle'],
      eventContent: map['eventContent'],
      allDayYn: map['allDayYn'],
      completeYn: map['completeYn'],
      isRecurring: map['isRecurring'],

    );
  }

}