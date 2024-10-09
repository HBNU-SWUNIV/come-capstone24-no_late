import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: onPreviousDay,
        ),
        InkWell(
          onTap: () => _selectDate(context),
          child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: onNextDay,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}