import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import 'add_event_screen.dart';

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
                        child: Text('이 항목만 삭제'),
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
              '일정 시작 시간: ${DateFormat('HH:mm').format(event.eventSttTime)}',
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
