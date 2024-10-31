import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleSettingsProvider with ChangeNotifier {
  int _startTime = 0;
  int _endTime = 24;

  int get startTime => _startTime;
  int get endTime => _endTime;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _startTime = prefs.getInt('startTime') ?? 0;
    _endTime = prefs.getInt('endTime') ?? 24;
    notifyListeners();
  }

  Future<void> saveSettings(int startTime, int endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startTime', startTime);
    await prefs.setInt('endTime', endTime);
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }
}