import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/event_provider.dart';
import '../model/event_model.dart';
import 'package:intl/intl.dart';

class CalendarBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final size = MediaQuery.of(context).size;
    final rowHeight = (size.height - kToolbarHeight - MediaQuery.of(context).padding.top) / 6;

    return TableCalendar<EventModel>(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: eventProvider.focusedDay,
      selectedDayPredicate: (day) => isSameDay(eventProvider.selectedDay, day),
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.none,
      eventLoader: eventProvider.getEventsForDay,
      onDaySelected: eventProvider.onDaySelected,
      rowHeight: rowHeight,
      daysOfWeekHeight: 50,
      headerVisible: false,
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.zero,
        tableBorder: TableBorder.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(context, day, eventProvider),
        selectedBuilder: (context, day, focusedDay) => _buildSelectedCell(context, day, eventProvider),
        todayBuilder: (context, day, focusedDay) => _buildTodayCell(context, day, eventProvider),
        outsideBuilder: (context, day, focusedDay) => _buildOutsideCell(context, day, eventProvider),
        dowBuilder: (context, day) => _buildDayOfWeek(day),
      ),
    );
  }

  Widget _buildCalendarCell(BuildContext context, DateTime day, EventProvider eventProvider) {
    return Stack(
      children: [
        Positioned(
          right: 5,
          top: 5,
          child: Text(
            day.day.toString(),
            style: TextStyle(
              fontSize: 16,
              color: day.weekday == DateTime.sunday ? Colors.red : Colors.black,
            ),
          ),
        ),
        Positioned.fill(
          top: 25,
          child: _buildEventsMarker(context, day, eventProvider.getEventsForDay(day)),
        ),
      ],
    );
  }

  Widget _buildSelectedCell(BuildContext context, DateTime day, EventProvider eventProvider) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green, width: 1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Text(
            day.day.toString(),
            style: TextStyle(fontSize: 16, color: Colors.green),
          ),
        ),
        Positioned.fill(
          top: 25,
          child: _buildEventsMarker(context, day, eventProvider.getEventsForDay(day)),
        ),
      ],
    );
  }

  Widget _buildTodayCell(BuildContext context, DateTime day, EventProvider eventProvider) {
    return Stack(
      children: [
        Positioned(
          right: 5,
          top: 5,
          child: Text(
            day.day.toString(),
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ),
        Positioned.fill(
          top: 25,
          child: _buildEventsMarker(context, day, eventProvider.getEventsForDay(day)),
        ),
      ],
    );
  }

  Widget _buildOutsideCell(BuildContext context, DateTime day, EventProvider eventProvider) {
    return Stack(
      children: [
        Positioned(
          right: 5,
          top: 5,
          child: Text(
            day.day.toString(),
            style: TextStyle(
              fontSize: 16,
              color: day.weekday == DateTime.sunday ? Colors.red.withOpacity(0.5) : Colors.grey,
            ),
          ),
        ),
        Positioned.fill(
          top: 25,
          child: _buildEventsMarker(context, day, eventProvider.getEventsForDay(day)),
        ),
      ],
    );
  }

  Widget _buildDayOfWeek(DateTime day) {
    if (day.weekday == DateTime.sunday) {
      final text = DateFormat.E("ko_KR").format(day);
      return Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      final text = DateFormat.E("ko_KR").format(day);
      return Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildEventsMarker(BuildContext context, DateTime date, List<EventModel> events) {
    if (events.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventTitle = event.eventTitle;
        final displayTitle = eventTitle.length > 15 ? '${eventTitle.substring(0, 15)}…' : eventTitle;

        return Container(
          margin: EdgeInsets.only(bottom: 2, left: 2, right: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: _getCategoryColor(event.categoryColor),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              displayTitle,
              style: TextStyle(color: Colors.black, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String? colorCode) {
    if (colorCode != null && colorCode.isNotEmpty) {
      try {
        return Color(int.parse(colorCode));
      } catch (e) {
        print('Error parsing color code: $colorCode');
      }
    }
    return Colors.grey;
  }
}