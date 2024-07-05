import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('showOnCalendar', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => EventModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<Map<String, String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('category').get();
      return Map.fromEntries(
        snapshot.docs.map((doc) => MapEntry(doc.id, doc.data()['colorCode'] as String)),
      );
    } catch (e) {
      print('Error loading categories: $e');
      return {};
    }
  }
}