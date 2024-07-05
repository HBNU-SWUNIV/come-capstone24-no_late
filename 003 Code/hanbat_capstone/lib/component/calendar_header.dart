import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import 'package:intl/intl.dart';

class CalendarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    return GestureDetector(
      onTap: () => eventProvider.showMonthPicker(context),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(
          DateFormat.yMMM('ko_KR').format(eventProvider.focusedDay),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}