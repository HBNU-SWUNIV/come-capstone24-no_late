import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CategoryProvider with ChangeNotifier {
  Map<String, String> _categoryColors = {};

  Map<String, String> get categoryColors => _categoryColors;

  Future<void> loadCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('userId', isEqualTo: user.uid)
          .get();

      _categoryColors = Map.fromEntries(
          snapshot.docs.map((doc) => MapEntry(doc.id, doc['colorCode'] as String))
      );

      notifyListeners();
      print('Loaded categories in provider: $_categoryColors'); // 디버깅용
    } catch (e) {
      print('Error loading categories in provider: $e');
    }
  }

  void updateCategoryColor(String categoryId, String colorCode) {
    _categoryColors[categoryId] = colorCode;
    notifyListeners();
  }
}