import 'package:flutter/material.dart';
import '../model/event_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<EventModel> get events => _events;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> fetchEvents() async {
    _events = await _firestoreService.getEvents();
    notifyListeners();
  }

  List<EventModel> getEventsForDay(DateTime day) {
    return _events.where((event) =>
    event.eventDate != null &&
        event.eventDate!.year == day.year &&
        event.eventDate!.month == day.month &&
        event.eventDate!.day == day.day
    ).toList();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void showMonthPicker(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (index) => currentYear - 50 + index);

    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('연도와 월을 선택하세요'),
              content: Container(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedYear = newValue!;
                        });
                      },
                      items: years.map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        children: List<Widget>.generate(12, (int index) {
                          final month = index + 1;
                          final monthName = DateFormat('MMMM', 'ko_KR').format(DateTime(2021, month));
                          return GestureDetector(
                            onTap: () {
                              final selectedDate = DateTime(selectedYear, month);
                              _focusedDay = selectedDate;
                              notifyListeners();
                              Navigator.pop(context);
                            },
                            child: Center(
                              child: Text(
                                monthName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}