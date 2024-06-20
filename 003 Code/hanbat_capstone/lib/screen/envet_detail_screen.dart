import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import 'add_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel? event;
  final EventResultModel? eventResult;
  final Function(bool deleteAllRecurrence) onEventDeleted;
  final Function(EventModel?) onEventEdited;
  final Function(EventResultModel?) onEventResultEdited;
  final DateTime? selectedDate;
  final VoidCallback? updateCalendar;

  EventDetailScreen({
    this.event,
    this.eventResult,
    required this.onEventDeleted,
    required this.onEventEdited,
    required this.onEventResultEdited,
    this.selectedDate,
    this.updateCalendar,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventModel? get event => widget.event;
  EventResultModel? get eventResult => widget.eventResult;

  @override
  Widget build(BuildContext context) {
    final bool isEventModel = event != null;
    final dynamic eventData = isEventModel ? event : eventResult;

    return Scaffold(
      appBar: AppBar(
        title: Text('일정 세부사항'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventData != null
                  ? (isEventModel ? eventData.eventTitle : eventData.eventRetTitle) ?? ''
                  : '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '날짜: ${eventData != null
                  ? (isEventModel
                  ? eventData.eventDate.toString().split(' ')[0]
                  : eventData.eventRetDate ?? '')
                  : ''}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              '일정 시작 시간: ${DateFormat('HH:mm').format(DateTime.parse(
                isEventModel
                    ? eventData.eventSttTime?.toIso8601String() ?? DateTime.now().toIso8601String()
                    : eventData.eventRetSttTime ?? DateTime.now().toIso8601String(),
              ))}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              '일정 종료 시간: ${DateFormat('HH:mm').format(DateTime.parse(
                isEventModel
                    ? eventData.eventEndTime?.toIso8601String() ?? DateTime.now().toIso8601String()
                    : eventData.eventRetEndTime ?? DateTime.now().toIso8601String(),
              ))}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              '세부사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              eventData != null
                  ? (isEventModel
                  ? eventData.eventContent ?? 'no details available'
                  : eventData.eventRetContent ?? 'no details available')
                  : 'no details available',
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    print('Editing event with ID: ${eventResult?.eventResultId ?? event?.eventId}');
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventScreen(
                          selectedDate: eventData != null
                              ? (isEventModel
                              ? eventData.eventDate
                              : DateTime.parse(eventData.eventRetDate))
                              : widget.selectedDate,
                          selectedTime: eventData != null
                              ? (isEventModel
                              ? eventData.eventSttTime
                              : DateTime.parse(eventData.eventRetSttTime))
                              : null,
                          event: isEventModel ? event : null,
                          actualevent: !isEventModel ? eventResult : null,
                          isFinalEvent: !isEventModel,
                          isEditing: true,
                        ),
                      ),
                    );

                    print('Result from AddEventScreen: $result');

                    if (result != null) {
                      try {
                        if (result is EventResultModel) {
                          print('Updating EventResultModel with ID: ${result.eventResultId}');
                          final docRef = FirebaseFirestore.instance
                              .collection('result_events')
                              .doc(result.eventResultId);

                          await docRef.set(result.toMap(), SetOptions(merge: true));
                          widget.onEventResultEdited(result);
                        } else if (result is EventModel) {
                          print('Updating EventModel with ID: ${result.eventId}');
                          final docRef = FirebaseFirestore.instance
                              .collection('events')
                              .doc(result.eventId);

                          await docRef.set(result.toMap(), SetOptions(merge: true));
                          widget.onEventEdited(result);
                        }
                        setState(() {
                          // 업데이트 후 UI를 갱신합니다.
                        });
                      } catch (e) {
                        print('Error updating event: $e');
                        // 에러 메시지를 사용자에게 표시하는 로직을 추가할 수 있습니다.
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    if (isEventModel && (event!.isRecurring ?? false)) {
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
                              onPressed: () async {
                                const deleteAllRecurrences = true;
                                await widget.onEventDeleted(deleteAllRecurrences);
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .where('isRecurring', isEqualTo: true)
                                    .where('eventTitle', isEqualTo: event!.eventTitle)
                                    .get()
                                    .then((querySnapshot) {
                                  for (var doc in querySnapshot.docs) {
                                    doc.reference.delete();
                                  }
                                });
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('삭제'),
                            ),
                            TextButton(
                              onPressed: () async {
                                const deleteAllRecurrences = false;
                                await widget.onEventDeleted(deleteAllRecurrences);
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event!.eventId)
                                    .delete();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('이 항목만 삭제'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // 반복되지 않는 일정 삭제
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('일정 삭제'),
                          content: Text('이 일정을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('취소'),
                            ),
                            TextButton(
                              onPressed: () async {
                                const deleteAllRecurrences = false;
                                await widget.onEventDeleted(deleteAllRecurrences);
                                await FirebaseFirestore.instance
                                    .collection(isEventModel ? 'events' : 'result_events')
                                    .doc(eventData!.eventId ?? eventData!.eventRetId)
                                    .delete();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
