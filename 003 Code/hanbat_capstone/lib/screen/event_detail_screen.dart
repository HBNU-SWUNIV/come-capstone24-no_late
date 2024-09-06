// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../model/event_model.dart';
// import '../model/event_result_model.dart';
// import 'add_event_screen.dart';
//
// class EventDetailScreen extends StatefulWidget {
//   final EventModel? event;
//   final EventResultModel? eventResult;
//   final Function(bool deleteAllRecurrence) onEventDeleted;
//   final Function(EventModel?)? onEventEdited;
//   final Function(EventResultModel?)? onEventResultEdited;
//   final DateTime? selectedDate;
//   final VoidCallback? updateCalendar;
//
//   EventDetailScreen({
//     this.event,
//     this.eventResult,
//     required this.onEventDeleted,
//     required this.onEventEdited,
//     this.onEventResultEdited,
//     this.selectedDate,
//     this.updateCalendar,
//   });
//
//   @override
//   _EventDetailScreenState createState() => _EventDetailScreenState();
// }
//
// class _EventDetailScreenState extends State<EventDetailScreen> {
//   EventModel? get event => widget.event;
//   EventResultModel? get eventResult => widget.eventResult;
//
//   Future<void> _deleteEvent(bool deleteAllRecurrence) async {
//     try {
//       if (deleteAllRecurrence) {
//         await FirebaseFirestore.instance
//             .collection('events')
//             .where('isRecurring', isEqualTo: true)
//             .where('eventTitle', isEqualTo: event!.eventTitle)
//             .get()
//             .then((querySnapshot) {
//           for (var doc in querySnapshot.docs) {
//             doc.reference.delete();
//           }
//         });
//       } else {
//         await FirebaseFirestore.instance
//             .collection('events')
//             .doc(event!.eventId)
//             .delete();
//       }
//       widget.onEventDeleted(false);
//       Navigator.pop(context);
//     } catch (e) {
//       _handleError('이벤트 삭제 중 오류가 발생했습니다: $e');
//     }
//   }
//
//   Future<void> _editEvent(EventModel? editedEvent) async {
//     if (editedEvent != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('events')
//             .doc(editedEvent.eventId)
//             .update(editedEvent.toMap());
//         widget.onEventEdited!(editedEvent);
//         setState(() {});
//       } catch (e) {
//         _handleError('이벤트 수정 중 오류가 발생했습니다: $e');
//       }
//     }
//   }
//
//   Future<void> _editEventResult(EventResultModel? editedEventResult) async {
//     if (editedEventResult != null) {
//       try {
//         final docRef = FirebaseFirestore.instance
//             .collection('result_events')
//             .doc(editedEventResult.eventResultId);
//         await docRef.set(editedEventResult.toMap(), SetOptions(merge: true));
//         widget.onEventResultEdited!(editedEventResult);
//         setState(() {});
//       } catch (e) {
//         _handleError('이벤트 결과 수정 중 오류가 발생했습니다: $e');
//       }
//     }
//   }
//
//   Widget _buildEventDetails(EventModel? eventModel, EventResultModel? eventResultModel) {
//     if (eventModel != null) {
//       return _buildEventModelDetails(eventModel);
//     } else if (eventResultModel != null) {
//       return _buildEventResultModelDetails(eventResultModel);
//     } else {
//       return Text('No event details available');
//     }
//   }
//
//   Widget _buildEventModelDetails(EventModel eventModel) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           eventModel.eventTitle,
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 20),
//         Text(
//           '날짜: ${eventModel.eventDate?.toString().split(' ')[0] ?? 'Unknown'}',
//           style: TextStyle(fontSize: 18),
//         ),
//         SizedBox(height: 10),
//         Text(
//           '일정 시작 시간: ${DateFormat('HH:mm').format(eventModel.eventSttTime ?? DateTime.now())}',
//           style: TextStyle(fontSize: 18),
//         ),
//         Text(
//           '일정 종료 시간: ${DateFormat('HH:mm').format(eventModel.eventEndTime ?? DateTime.now())}',
//           style: TextStyle(fontSize: 18),
//         ),
//         SizedBox(height: 20),
//         Text(
//           '세부사항',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         Text(
//           eventModel.eventContent ?? 'no details available',
//           style: TextStyle(fontSize: 18),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildEventResultModelDetails(EventResultModel eventResultModel) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           eventResultModel.eventResultTitle,
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 20),
//         Text(
//           '날짜: ${eventResultModel.eventResultDate?.toString().split(' ')[0] ?? 'Unknown'}',
//           style: TextStyle(fontSize: 18),
//         ),
//         SizedBox(height: 10),
//         Text(
//           '일정 시작 시간: ${DateFormat('HH:mm').format(eventResultModel.eventResultSttTime ?? DateTime.now())}',
//           style: TextStyle(fontSize: 18),
//         ),
//         Text(
//           '일정 종료 시간: ${DateFormat('HH:mm').format(eventResultModel.eventResultEndTime ?? DateTime.now())}',
//           style: TextStyle(fontSize: 18),
//         ),
//         SizedBox(height: 20),
//         Text(
//           '세부사항',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         Text(
//           eventResultModel.eventResultContent ?? 'no details available',
//           style: TextStyle(fontSize: 18),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActions(BuildContext context, EventModel? eventModel, EventResultModel? eventResultModel) {
//     final isEventModel = eventModel != null;
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         IconButton(
//           icon: Icon(Icons.edit),
//           onPressed: () async {
//             final result = await Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => AddEventScreen(
//                   selectedDate: isEventModel ? eventModel!.eventDate : eventResultModel!.eventResultDate,
//                   selectedTime: isEventModel ? (eventModel!.eventSttTime ?? DateTime.now()) : (eventResultModel!.eventResultSttTime ?? DateTime.now()),
//                   event: isEventModel ? eventModel : null,
//                   actualevent: !isEventModel ? eventResultModel : null,
//                   isFinalEvent: !isEventModel,
//                   isEditing: true,
//                 ),
//               ),
//             );
//             if (result != null) {
//               if (result is EventResultModel) {
//                 await _editEventResult(result);
//               } else if (result is EventModel) {
//                 await _editEvent(result);
//               }
//             }
//           },
//         ),
//         IconButton(
//           icon: Icon(Icons.delete),
//           onPressed: () async {
//             if (isEventModel && (eventModel!.isRecurring ?? false)) {
//               _showDeleteRecurrenceDialog(context, eventModel);
//             } else {
//               _showDeleteDialog(context, isEventModel, eventModel, eventResultModel);
//             }
//           },
//         ),
//       ],
//     );
//   }
//
//   void _showDeleteRecurrenceDialog(BuildContext context, EventModel eventModel) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('반복 일정 삭제'),
//         content: Text('이 일정의 모든 반복 항목을 삭제하시겠습니까?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('취소'),
//           ),
//           TextButton(
//             onPressed: () async {
//               await _deleteEvent(true);
//               Navigator.pop(context);
//             },
//             child: Text('삭제'),
//           ),
//           TextButton(
//             onPressed: () async {
//               await _deleteEvent(false);
//               Navigator.pop(context);
//             },
//             child: Text('이 항목만 삭제'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showDeleteDialog(BuildContext context, bool isEventModel, EventModel? eventModel, EventResultModel? eventResultModel) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('일정 삭제'),
//         content: Text('이 일정을 삭제하시겠습니까?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('취소'),
//           ),
//           TextButton(
//             onPressed: () async {
//               if (isEventModel) {
//                 await _deleteEvent(false);
//               } else {
//                 await FirebaseFirestore.instance
//                     .collection('result_events')
//                     .doc(eventResultModel!.eventResultId)
//                     .delete();
//                 widget.onEventDeleted(false);
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               }
//             },
//             child: Text('삭제'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _handleError(String errorMessage) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('오류'),
//         content: Text(errorMessage),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('확인'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     try {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('일정 세부사항'),
//           centerTitle: true,
//         ),
//         body: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildEventDetails(event, eventResult),
//               Spacer(),
//               _buildActions(context, event, eventResult),
//             ],
//           ),
//         ),
//       );
//     } catch (e, stackTrace) {
//       print('Error in build method: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('오류가 발생했습니다: $e');
//       return Scaffold(
//         body: Center(child: Text('오류가 발생했습니다.')),
//       );
//     }
//   }
// }

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
  final Function(EventModel?)? onEventEdited;
  final Function(EventResultModel?)? onEventResultEdited;
  final DateTime? selectedDate;
  final VoidCallback? updateCalendar;

  EventDetailScreen({
    this.event,
    this.eventResult,
    required this.onEventDeleted,
    required this.onEventEdited,
    this.onEventResultEdited,
    this.selectedDate,
    this.updateCalendar,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _currentEvent;
  late EventResultModel _currentEventResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event ??
        EventModel(
          eventId: '',
          eventTitle: '',
          eventDate: DateTime.now(),
          eventContent: '',
          categoryId: '',
          userId: '',
          eventSttTime: DateTime.now(),
          eventEndTime: DateTime.now(),
          isAllDay: false,
          completedYn: 'N',
          isRecurring: false,
          showOnCalendar: true,
          originalEventId: '',
        );
    _currentEventResult = widget.eventResult ??
        EventResultModel(
          eventResultId: '',
          eventId: '',
          categoryId: '',
          userId: '',
          eventResultDate: DateTime.now(),
          eventResultSttTime: DateTime.now(),
          eventResultEndTime: DateTime.now(),
          eventResultTitle: '',
          eventResultContent: '',
          isAllDay: false,
          completeYn: 'N',
        );
  }
  Future<void> _reloadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.event != null) {
        // 일반 이벤트 리로드
        final updatedEvent = await FirebaseFirestore.instance
            .collection('events')
            .doc(_currentEvent.eventId)
            .get();
        if (updatedEvent.exists) {
          setState(() {
            _currentEvent = EventModel.fromMap(updatedEvent.data()!);
          });
        }
      } else if (widget.eventResult != null) {
        // 결과 이벤트 리로드
        final updatedEventResult = await FirebaseFirestore.instance
            .collection('result_events')
            .doc(_currentEventResult.eventResultId)
            .get();
        if (updatedEventResult.exists) {
          setState(() {
            _currentEventResult = EventResultModel.fromMap(updatedEventResult.data()!);
          });
        }
      }
    } catch (e) {
      print('Error reloading event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 새로 불러오는 데 실패했습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<void> _deleteEvent(bool deleteAllRecurrence) async {
    try {
      if (deleteAllRecurrence) {
        await FirebaseFirestore.instance
            .collection('events')
            .where('isRecurring', isEqualTo: true)
            .where('eventTitle', isEqualTo: _currentEvent.eventTitle)
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(_currentEvent.eventId)
            .delete();
      }
      widget.onEventDeleted(false);
      Navigator.pop(context);
    } catch (e) {
      _handleError('이벤트 삭제 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _editEvent(EventModel editedEvent) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(editedEvent.eventId)
          .update(editedEvent.toMap());
      widget.onEventEdited!(editedEvent);
      setState(() {
        _currentEvent = editedEvent;
      });
      widget.updateCalendar?.call();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('일정이 성공적으로 수정되었습니다.')));
    } catch (e) {
      _handleError('이벤트 수정 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _editEventResult(EventResultModel editedEventResult) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('result_events')
          .doc(editedEventResult.eventResultId);
      await docRef.set(editedEventResult.toMap(), SetOptions(merge: true));
      widget.onEventResultEdited!(editedEventResult);
      setState(() {
        _currentEventResult = editedEventResult;
      });
      widget.updateCalendar?.call();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 결과가 성공적으로 수정되었습니다.'))
      );
    } catch (e) {
      _handleError('이벤트 결과 수정 중 오류가 발생했습니다: $e');
    }
  }

  Widget _buildEventDetails() {
    if (widget.event != null) {
      return _buildEventModelDetails(_currentEvent);
    } else if (widget.eventResult != null) {
      return _buildEventResultModelDetails(_currentEventResult);
    } else {
      return Text('No event details available');
    }
  }

  Widget _buildEventModelDetails(EventModel eventModel) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventModel.eventTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildInfoRow(Icons.calendar_today, '날짜',
                eventModel.eventDate?.toString().split(' ')[0] ?? 'Unknown'),
            _buildInfoRow(
                Icons.access_time,
                '시작 시간',
                DateFormat('HH:mm')
                    .format(eventModel.eventSttTime ?? DateTime.now())),
            _buildInfoRow(
                Icons.access_time,
                '종료 시간',
                DateFormat('HH:mm')
                    .format(eventModel.eventEndTime ?? DateTime.now())),
            SizedBox(height: 20),
            Text(
              '세부사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              eventModel.eventContent ?? '세부사항이 없습니다.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventResultModelDetails(EventResultModel eventResultModel) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventResultModel.eventResultTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildInfoRow(
                Icons.calendar_today,
                '날짜',
                eventResultModel.eventResultDate?.toString().split(' ')[0] ??
                    'Unknown'),
            _buildInfoRow(
                Icons.access_time,
                '시작 시간',
                DateFormat('HH:mm').format(
                    eventResultModel.eventResultSttTime ?? DateTime.now())),
            _buildInfoRow(
                Icons.access_time,
                '종료 시간',
                DateFormat('HH:mm').format(
                    eventResultModel.eventResultEndTime ?? DateTime.now())),
            SizedBox(height: 20),
            Text(
              '세부사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              eventResultModel.eventResultContent ?? '세부사항이 없습니다.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isEventModel = widget.event != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: Icon(
            Icons.edit,
            color: Colors.black,
          ),
          label: Text(
            '수정',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[900],
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEventScreen(
                  selectedDate: widget.event != null
                      ? _currentEvent.eventDate
                      : _currentEventResult.eventResultDate,
                  selectedTime: widget.event != null
                      ? _currentEvent.eventSttTime
                      : _currentEventResult.eventResultSttTime,
                  event: widget.event != null ? _currentEvent : null,
                  actualevent:
                      widget.event == null ? _currentEventResult : null,
                  isFinalEvent: widget.event == null,
                  isEditing: true,
                ),
              ),
            );
            if (result != null) {
              // if (result is EventResultModel) {
              //   await _editEventResult(result);
              // } else if (result is EventModel) {
              //   await _editEvent(result);
              // }
              // setState(() {
              //   if (result is EventResultModel) {
              //     _currentEventResult = result;
              //   } else if (result is EventModel) {
              //     _currentEvent = result;
              //   }
              // });
              await _reloadEvent();  // 여기서 이벤트를 리로드합니다.

              widget.updateCalendar?.call();
            }
          },
        ),
        ElevatedButton.icon(
          icon: Icon(
            Icons.delete,
            color: Colors.black,
          ),
          label: Text(
            '삭제',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[900],
          ),
          onPressed: () async {
            if (isEventModel && (_currentEvent.isRecurring ?? false)) {
              _showDeleteRecurrenceDialog(context);
            } else {
              _showDeleteDialog(context, isEventModel);
            }
          },
        ),
      ],
    );
  }

  void _showDeleteRecurrenceDialog(BuildContext context) {
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
              await _deleteEvent(true);
              Navigator.pop(context);
            },
            child: Text('모두 삭제'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteEvent(false);
              Navigator.pop(context);
            },
            child: Text('이 항목만 삭제'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isEventModel) {
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
              if (isEventModel) {
                await _deleteEvent(false);
              } else {
                await FirebaseFirestore.instance
                    .collection('result_events')
                    .doc(_currentEventResult!.eventResultId)
                    .delete();
                widget.onEventDeleted(false);
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _handleError(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text('일정 세부사항'),
          centerTitle: true,
        ),
        body: _isLoading
          ? Center(child:  CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEventDetails(),
                  SizedBox(height: 20),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        );
    } catch (e, stackTrace) {
      print('Error in build method: $e');
      print('Stack trace: $stackTrace');
      _handleError('오류가 발생했습니다: $e');
      return Scaffold(
        body: Center(child: Text('오류가 발생했습니다.')),
      );
    }
  }
}
