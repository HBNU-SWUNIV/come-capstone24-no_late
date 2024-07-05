
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return null;
    }
  }

  Future<List<EventModel>> getEvents() async {
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    List<EventModel> events = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return EventModel(
        eventTitle: data['eventTitle'] ?? 'No title',
        eventDate: _toDate(data['eventDate']),
        eventContent: data['eventContent'] ?? 'No content',
        eventId: doc.id,
        categoryId: data['categoryId'] ?? '',
        userId: data['userId'] ?? '',
        eventSttTime: _toDate(data['eventSttTime']),
        eventEndTime: _toDate(data['eventEndTime']),
        allDayYn: data['allDayYn'] ?? 'N',
        completeYn: data['completeYn'] ?? 'N',
        isRecurring: data['isRecurring'] ?? false,
      );
    }).toList();
    return events;
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> updateEvent(String eventId, EventModel updatedEvent) async {
    await _firestore.collection('events').doc(eventId).update(updatedEvent.toMap());
  }
}