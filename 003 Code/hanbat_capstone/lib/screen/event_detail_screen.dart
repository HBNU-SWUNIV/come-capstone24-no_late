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
    final eventData = isEventModel ? (event as EventModel) : (eventResult as EventResultModel);
    final EventModel? eventModel = isEventModel ? (eventData as EventModel) : null;
    final EventResultModel? eventResultModel = !isEventModel ? (eventData as EventResultModel) : null;

    print('isEventModel: $isEventModel');
    print('eventData type: ${eventData.runtimeType}');
    print('eventData: $eventData');


    try {
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
                isEventModel ? (eventData as EventModel).eventTitle : (eventData as EventResultModel).eventResultTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '날짜: ${isEventModel
                    ? ((eventData as EventModel).eventDate?.toString().split(' ')[0] ?? 'Unknown')
                    : ((eventData as EventResultModel).eventResultDate?.toString().split(' ')[0] ?? 'Unknown')}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                '일정 시작 시간: ${DateFormat('HH:mm').format(
                    isEventModel
                        ? ((eventData as EventModel).eventSttTime ?? DateTime.now())
                        : ((eventData as EventResultModel).eventResultSttTime ?? DateTime.now())
                )}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                '일정 종료 시간: ${DateFormat('HH:mm').format(
                    isEventModel
                        ? ((eventData as EventModel).eventEndTime ?? DateTime.now())
                        : ((eventData as EventResultModel).eventResultEndTime ?? DateTime.now())
                )}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Text(
                '세부사항',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                isEventModel
                    ? ((eventData as EventModel).eventContent ?? 'no details available')
                    : ((eventData as EventResultModel).eventResultContent ?? 'no details available'),
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
                            selectedDate: isEventModel
                                ? (eventData as EventModel).eventDate
                                : (eventData as EventResultModel).eventResultDate,
                            selectedTime: isEventModel
                                ? ((eventData as EventModel).eventSttTime ?? DateTime.now())
                                : ((eventData as EventResultModel).eventResultSttTime ?? DateTime.now()),

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
                                      .doc(isEventModel ? eventModel!.eventId : eventResultModel!.eventResultId)
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
    } catch (e, stackTrace) {
      print('Error in build method: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(child: Text('오류가 발생했습니다: $e')),
      );
    }
  }
}
