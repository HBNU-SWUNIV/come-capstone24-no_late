import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CategoryProvider extends ChangeNotifier {
  Map<String, String> _categoryColors = {};

  Map<String, String> get categoryColors => _categoryColors;

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> loadCategories() async {
    _categoryColors = await _firestoreService.getCategories();
    notifyListeners();
  }
}