import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_result_model.dart';

class Schedule_CRUD {
  // createEventResult 메서드 추가
  static Future<void> createEventResult(EventResultModel eventResult) async {
    final eventResultRef = FirebaseFirestore.instance.collection('eventResults').doc();
    await eventResultRef.set(eventResult.toMap());
  }

  // getEventResultsByDate 메서드 추가
  static Future<List<EventResultModel>> getEventResultsByDate(DateTime date) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventResults')
        .where('eventResultDate', isEqualTo: date)
        .get();
    return snapshot.docs.map((doc) => EventResultModel.fromMap(doc.data())).toList();
  }

  // updateEventResult 메서드 추가
  static Future<void> updateEventResult(EventResultModel updatedEventResult) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventResults')
        .where('eventResultId', isEqualTo: updatedEventResult.eventResultId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update(updatedEventResult.toMap());
    }
  }

  // deleteEventResult 메서드 추가
  static Future<void> deleteEventResult(EventResultModel eventResult) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventResults')
        .where('eventResultId', isEqualTo: eventResult.eventResultId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}