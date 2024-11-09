// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../model/event_model.dart';
// import 'add_event_screen.dart';
// import 'event_detail_screen.dart';
//
//
// class DayEventsScreen extends StatefulWidget {
//   final List<EventModel> events;
//   final DateTime selectedDate;
//   final VoidCallback updateCalendar;
//
//   DayEventsScreen({
//     required this.events,
//     required this.selectedDate,
//     required this.updateCalendar,
//   });
//
//   @override
//   _DayEventsScreenState createState() => _DayEventsScreenState();
// }
//
// class _DayEventsScreenState extends State<DayEventsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _fetchEvents();
//   }
//
//   @override
//   void didUpdateWidget(covariant DayEventsScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedDate != widget.selectedDate) {
//       _fetchEvents();
//     }
//   }
//
//   void _fetchEvents() async {
//     final snapshot = await FirebaseFirestore.instance.collection('events').get();
//     final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
//     setState(() {
//       widget.events
//         ..clear()
//         ..addAll(events.where((event) => isSameDay(event.eventDate, widget.selectedDate)));
//     });
//     widget.updateCalendar();
//   }
//
//   Future<void> _deleteEvent(EventModel event) async {
//     await FirebaseFirestore.instance.collection('events').doc(event.eventId).delete();
//     _fetchEvents();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("${widget.selectedDate.toString().split(' ')[0]} 일정"),
//         centerTitle: true,
//       ),
//       body: ListView.builder(
//         itemCount: widget.events.length,
//         itemBuilder: (context, index) {
//           final event = widget.events[index];
//           return ListTile(
//             title: Text(event.eventTitle),
//             subtitle: Text(DateFormat('HH:mm').format(event.eventSttTime ?? DateTime.now())),
//             trailing: IconButton(
//               icon: Icon(Icons.delete),
//               onPressed: () => _deleteEvent(event),
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => EventDetailScreen(
//                     event: event,
//                     onEventDeleted: (deleteAllRecurrences) async {
//                       if (deleteAllRecurrences) {
//                         final snapshot = await FirebaseFirestore.instance
//                             .collection('events')
//                             .where('eventId', isEqualTo: event.eventId)
//                             .where('isRecurring', isEqualTo: true)
//                             .get();
//                         final batch = FirebaseFirestore.instance.batch();
//                         for (final doc in snapshot.docs) {
//                           batch.delete(doc.reference);
//                         }
//                         await batch.commit();
//                       } else {
//                         await _deleteEvent(event);
//                       }
//                       _fetchEvents();
//                     },
//                     onEventEdited: (editedEvent) async {
//                       await FirebaseFirestore.instance
//                           .collection('events')
//                           .doc(event.eventId)
//                           .update(editedEvent?.toMap() ?? {});
//                       _fetchEvents();
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AddEventScreen(selectedDate: widget.selectedDate),
//             ),
//           );
//           _fetchEvents();
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../model/event_model.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';

class DayEventsScreen extends StatefulWidget {
  final List<EventModel> events;
  final DateTime selectedDate;
  final VoidCallback updateCalendar;

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

  Future<void> _navigateToEventDetail(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          event: event,
          onEventDeleted: (deleteAllRecurrences) async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null || user.uid != event.userId) {
              print('Unauthorized delete attempt');
              return;
            }
            if (deleteAllRecurrences) {
              final snapshot = await FirebaseFirestore.instance
                  .collection('events')
                  .where('eventId', isEqualTo: event.eventId)
                  .where('isRecurring', isEqualTo: true)
                  .where('userId', isEqualTo: user.uid)
                  .get();
              final batch = FirebaseFirestore.instance.batch();
              for (final doc in snapshot.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
            } else {
              await _deleteEvent(event);
            }
          },
          onEventEdited: (editedEvent) async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null || user.uid != event.userId) {
              print('Unauthorized edit attempt');
              return;
            }

            await FirebaseFirestore.instance
                .collection('events')
                .doc(event.eventId)
                .update(editedEvent?.toMap() ?? {});
          },
        ),
      ),
    );

    // 세부 사항 페이지에서 돌아온 후 항상 이벤트를 다시 불러옵니다.
    await _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .get();

      final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();

      setState(() {
        widget.events
          ..clear()
          ..addAll(events.where((event) => isSameDay(event.eventDate, widget.selectedDate)));

        widget.events.sort((a, b) => a.eventSttTime!.compareTo(b.eventSttTime!));
      });

      widget.updateCalendar();
    } catch (e) {
      print('Error fetching events: $e');
      // 에러 처리 (예: 사용자에게 알림 표시)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 불러오는 중 오류가 발생했습니다.')),
      );
    }
  }


  // void _fetchEvents() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     print('No user logged in');
  //     return;
  //   }
  //
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('events').where('userId', isEqualTo: user.uid).get();
  //   final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
  //   setState(() {
  //     widget.events
  //       ..clear()
  //       ..addAll(events.where((event) => isSameDay(event.eventDate, widget.selectedDate)));
  //
  //     widget.events.sort((a, b) => a.eventSttTime!.compareTo(b.eventSttTime!));
  //
  //   });
  //   widget.updateCalendar();
  // }

  String _getTimeDifference(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);

    if (eventTime.isBefore(now)) {
      // 이벤트 시작 시간이 현재 시간보다 이전인 경우
      if (eventTime.add(Duration(hours: 2)).isAfter(
          now)) { // 예: 2시간 동안 진행 중으로 간주
        return '진행 중';
      } else {
        return '종료됨';
      }
    } else {
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 후';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 후';
      } else {
        return '${difference.inDays}일 후';
      }
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != event.userId) {
      print('Unauthorized delete attempt');
      return;
    }
    await FirebaseFirestore.instance.collection('events').doc(event.eventId).delete();
    _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 MM월 dd일').format(widget.selectedDate),

        ),
        centerTitle: true,

      ),
      body: Container(

        child: widget.events.isEmpty
            ? Center(
          child: Text(
            '오늘의 일정이 없습니다.',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        )

            : ListView.builder(
          itemCount: widget.events.length,
          itemBuilder: (context, index) {
            final event = widget.events[index];
            if (event == null) {
              return SizedBox.shrink(); // 또는 다른 적절한 위젯 반환
            }
            final timeDifference = _getTimeDifference(event.eventSttTime!);
            return Card(
              color: Colors.white,
              elevation: 2,
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    event.eventTitle.substring(0, 1),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  event.eventTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('HH:mm').format(event.eventSttTime ?? DateTime.now())} - ${DateFormat('HH:mm').format(event.eventEndTime ?? DateTime.now())}',
                      ),
                      Text(
                        timeDifference,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color:  Colors.lightBlue[900],),
                  onPressed: () => _showDeleteConfirmationDialog(event),
                ),
                onTap: () => _navigateToEventDetail(event),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEvent(),
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor:  Colors.lightBlue[900],
      ),
    );
  }

  void _showDeleteConfirmationDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 경고 아이콘
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              SizedBox(height: 24),

              // 제목
              Text(
                '일정 삭제',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // 내용
              Text(
                '이 일정을 삭제하시겠습니까?\n삭제된 일정은 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),

              // 버튼
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // 삭제 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteEvent(event);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _navigateToEventDetail(EventModel event) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EventDetailScreen(
  //         event: event,
  //         onEventDeleted: (deleteAllRecurrences) async {
  //           final user = FirebaseAuth.instance.currentUser;
  //           if (user == null || user.uid != event.userId) {
  //             print('Unauthorized delete attempt');
  //             return;
  //           }
  //           if (deleteAllRecurrences) {
  //             final snapshot = await FirebaseFirestore.instance
  //                 .collection('events')
  //                 .where('eventId', isEqualTo: event.eventId)
  //                 .where('isRecurring', isEqualTo: true)
  //                 .where('userId', isEqualTo: user.uid)
  //                 .get();
  //             final batch = FirebaseFirestore.instance.batch();
  //             for (final doc in snapshot.docs) {
  //               batch.delete(doc.reference);
  //             }
  //             await batch.commit();
  //           } else {
  //             await _deleteEvent(event);
  //           }
  //           _fetchEvents();
  //         },
  //         onEventEdited: (editedEvent) async {
  //           final user = FirebaseAuth.instance.currentUser;
  //           if (user == null || user.uid != event.userId) {
  //             print('Unauthorized edit attempt');
  //             return;
  //           }
  //
  //           await FirebaseFirestore.instance
  //               .collection('events')
  //               .doc(event.eventId)
  //               .update(editedEvent?.toMap() ?? {});
  //           _fetchEvents();
  //         },
  //       ),
  //     ),
  //   );
  // }

  void _navigateToAddEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(selectedDate: widget.selectedDate),
      ),
    );
    _fetchEvents();
  }
}