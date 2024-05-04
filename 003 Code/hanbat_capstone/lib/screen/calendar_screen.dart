
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';



class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

Map<DateTime, List<Event>> kEvents = {};

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Event>> selectedEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<Event>> _selectedEvents;

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

  Map<DateTime, List<Event>> events = {};

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    DateTime dateKey = DateTime.utc(day.year, day.month, day.day);
    var events = kEvents[dateKey] ?? [];

    return events;
  }

  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    if (events.isEmpty) return Container();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Container(
          child: Text(
            events[index].title,
            style: TextStyle(color: Colors.black, fontSize: 10),
          ),
        );
      },
    );
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
        context, MaterialPageRoute(builder: (context) => AddEventPage()));

    if (newEvent != null) {
      setState(() {
        DateTime eventDate = DateTime.utc(
            newEvent.date.year, newEvent.date.month, newEvent.date.day);
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
    final size = MediaQuery.of(context).size;
    final rowHeight =
        (size.height - kToolbarHeight - MediaQuery.of(context).padding.top) / 7;

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddEventPage,
          backgroundColor: Colors.white,
          child: const Icon(Icons.add_circle_outline),
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
  final List<Event> events;
  final DateTime selectedDate;
  final VoidCallback updateCalendar;

  DayEventsPage({
    required this.events,
    required this.selectedDate,
    required this.updateCalendar,
  });

  @override
  _DayEventsPageState createState() => _DayEventsPageState();
}

class _DayEventsPageState extends State<DayEventsPage> {
  // ...
  void _addEvent() async {
    final newEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AddEventPage(selectedDate: widget.selectedDate)),
    );

    if (newEvent != null) {
      setState(() {
        widget.events.add(newEvent);
      });
    }
  }

  void _deleteEvent(Event event) {
    setState(() {
      widget.events.remove(event);
      widget.updateCalendar();
    });
  }

  void _editEvent(Event event) async {
    final editedEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(
          selectedDate: event.date,
          event: event,
        ),
      ),
    );

    if (editedEvent != null) {
      setState(() {
        final index = widget.events.indexOf(event);
        widget.events[index] = editedEvent;
      });
    }
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
            title: Text(event.title),
            subtitle: Text(event.time.format(context)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editEvent(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteEvent(event),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                    event: event,
                    onEventDeleted: () => _deleteEvent(event),
                    onEventEdited: (editedEvent) => setState(() {
                      final index = widget.events.indexOf(event);
                      widget.events[index] = editedEvent;
                    }),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;
  final Event? event;

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
    selectedTime = widget.event?.time ?? TimeOfDay.now();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    isRecurring = widget.event?.isRecurring ?? false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
                // `bool?` 타입을 명시
                if (value != null) {
                  // `value`가 `null`이 아닐 때만 상태를 업데이트
                  setState(() {
                    isRecurring = value;
                  });
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null) {
                  final newEvent = Event(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    date: selectedDate!,
                    time: selectedTime,
                    isRecurring: isRecurring,
                  );
                  Navigator.pop(context, newEvent);

                  // Process data
                  // DateTime eventDate = selectedDate ?? DateTime.now();
                  //
                  //
                  // Event newEvent = Event(
                  //     title: _titleController.text,
                  //     description: _descriptionController.text,
                  //     date: eventDate,
                  //     time: selectedTime,
                  //     isRecurring: isRecurring
                  // );
                  //
                  // Navigator.pop(context, newEvent);
                }
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
  final Event event;
  final VoidCallback onEventDeleted;
  final Function(Event) onEventEdited;

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
              final editedEvent = await Navigator.push<Event>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventPage(
                    selectedDate: event.date,
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
              onEventDeleted();
              Navigator.pop(context);
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
              event.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Date: ${event.date.toString().split(' ')[0]}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Time: ${event.time.format(context)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              event.description,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final bool isRecurring;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.isRecurring = false,
  });
  @override
  String toString() {
    return 'Event: $title, Date: $date, Time: $time';
  }
}

