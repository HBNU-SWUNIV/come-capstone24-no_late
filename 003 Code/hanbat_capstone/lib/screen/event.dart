import 'package:flutter/material.dart';

class Event {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final bool isRecurring;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.isRecurring = false,
  });
  @override
  String toString() {
    return 'Event: $title, Date: $date, Time: $time';
  }
}