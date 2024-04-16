import 'package:flutter/material.dart';
import 'event.dart';
import 'event_details_page.dart';
import 'AddEventPage.dart';

class DayEventsPage extends StatefulWidget {
  final List<Event> events;
  final DateTime selectedDate;
  final VoidCallback updateCalendar;


  DayEventsPage({required this.events, required this.selectedDate,required this.updateCalendar,});

  @override
  _DayEventsPageState createState() => _DayEventsPageState();
}

class _DayEventsPageState extends State<DayEventsPage> {
  // ...
  void _addEvent() async {
    final newEvent = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => AddEventPage(selectedDate: widget.selectedDate)),
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
        title: Text("Events for ${widget.selectedDate.toString().split(' ')[0]}"),
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


