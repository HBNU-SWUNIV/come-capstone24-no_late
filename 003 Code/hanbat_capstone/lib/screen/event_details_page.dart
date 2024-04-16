import 'package:flutter/material.dart';
import 'event.dart';
import 'add_event_screen.dart';

class EventDetailsPage extends StatelessWidget {
  final Event event;
  final VoidCallback onEventDeleted;
  final Function(Event) onEventEdited;


  EventDetailsPage({required this.event,required this.onEventDeleted,
    required this.onEventEdited,});

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