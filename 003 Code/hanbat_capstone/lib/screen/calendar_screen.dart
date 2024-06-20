import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';
import 'add_event_screen.dart';
import 'package:intl/intl.dart';

import 'day_events_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

Map<DateTime, List<EventModel>> kEvents = {};
// 일정 목록을 저장 하는 맵

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // 캘린더 형식 : 달
  DateTime _focusedDay = DateTime.now(); // 현재 포거스된 날짜
  DateTime? _selectedDay; //선택한 날짜
  late ValueNotifier<List<EventModel>> _selectedEvents;
  //선택한 날짜의 이벤트 목록
  bool _isLoading= true;

  @override
  void initState() {
    super.initState(); // 위젯 처음 생성시 호출
    _selectedDay = _focusedDay; //// _selectedDay 초기화
    _selectedEvents = ValueNotifier<List<EventModel>>([]); // 빈목록으로 초기화 해 일정 가져옴
    _fetchEvents();

  }


  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      final events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
      setState(() {
        kEvents = _groupEvents(events);
        _isLoading = false;
      });
    } catch (error) {
      // 에러 처리 로직 추가
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<EventModel>> _groupEvents(List<EventModel> events) {
    //일정 목록을 날짜 별로 그룹화
    final groupedEvents = <DateTime, List<EventModel>>{};
    for (final event in events) {
      final date = DateTime.utc(
        event.eventDate?.year ?? 0, event.eventDate?.month ?? 0, event.eventDate?.day?? 0, );
      groupedEvents
          .putIfAbsent(date, () => [])
          .add(event); // 각 날짜에 해당하는 일정들을 groupedEvents에 저장
    }
    return groupedEvents;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    // 특정날자의 일정 목록을 반환 -> 일정 X ->빈목록 반환
    return kEvents[day] ?? [];
  }

  Widget _buildEventsMarker(DateTime date, List<EventModel> events) {
    // 날짜의 일정 표시 생성
    // 일정이 없는 경우 -> 빈 위젯 생성
    if (events.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final eventTitle = events[index].eventTitle;
        final displayTitle =
        eventTitle.length > 20 ? '${eventTitle.substring(0, 20)}…' : eventTitle;

        return Text(
          displayTitle,
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.black, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents.value = _getEventsForDay(selectedDay);
    });

    // 선택한 날짜의 이벤트를 가져와서 DayEventsScreen으로 이동
    final selectedEvents = _getEventsForDay(selectedDay);

    if (selectedEvents.isEmpty) {
      // 일정이 없는 경우, 일정 추가 화면으로 이동
      final selectedDateWithoutZ = selectedDay.toIso8601String().replaceAll('Z', '');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEventScreen(
            selectedDate: DateTime.parse(selectedDateWithoutZ),
          ),
        ),
      );
      if (result != null) {
        // 일정 추가 후 캘린더 갱신
        await _fetchEvents();
      }
    } else {
      // 일정이 있는 경우, 스케줄러 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RootScreen(selectedDate: selectedDay),
        ),
      ).then((_) {
        _fetchEvents();
      });
    }
  }

  void _showMonthPicker() {
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
                          final monthName = [
                            '1월',
                            '2월',
                            '3월',
                            '4월',
                            '5월',
                            '6월',
                            '7월',
                            '8월',
                            '9월',
                            '10월',
                            '11월',
                            '12월'
                          ][index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMonth = month;
                              });
                              final selectedDate =
                              DateTime(selectedYear, selectedMonth);
                              this.setState(() {
                                _focusedDay = selectedDate;
                              });
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rowHeight =
        (size.height - kToolbarHeight - MediaQuery.of(context).padding.top) / 6;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          TableCalendar<EventModel>(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            // onFormatChanged: (format) {
            //   if (_calendarFormat != format) {
            //     setState(() {
            //       _calendarFormat = format;
            //     });
            //   }
            // }, // 스크롤 하면 2주로 캘린더로 벼환
            // availableCalendarFormats: const {
            //   CalendarFormat.month: 'Month',  // 월간 형식만 제공
            // },
            availableGestures: AvailableGestures.none,

            calendarStyle: CalendarStyle(
              cellMargin: EdgeInsets.zero,
              tableBorder: TableBorder.all(
                color: Colors.grey[300]!,
                width: 0.5,
              ),
            ),
            rowHeight: rowHeight,
            daysOfWeekHeight: 50,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
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
              },
              markerBuilder: (context, day, events) =>
                  _buildEventsMarker(day, events),
              defaultBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: day.weekday == DateTime.sunday
                              ? Colors.red
                              : Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
              outsideBuilder: (context, day, focusedDay) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: day.weekday == DateTime.sunday
                              ? Colors.red[200]!
                              : Colors.grey[600]!,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ]);
              },
            ),
            onHeaderTapped: (_) => _showMonthPicker(),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              titleCentered: true,
              formatButtonVisible: false,
              titleTextFormatter: (date, locale) =>
                  DateFormat.yMMM(locale).format(date),
            ),
          ),
        ],
      ),
    );
  }
}