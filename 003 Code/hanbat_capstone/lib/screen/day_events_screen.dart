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
//                           .update(editedEvent.toMap());
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
