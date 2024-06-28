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
  final Key? key;

  CalendarScreen({this.key}) : super(key: key);

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

Map<DateTime, List<EventModel>> kEvents = {};
// 일정 목록을 저장 하는 맵

class CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // 캘린더 형식 : 달
  DateTime _focusedDay = DateTime.now(); // 현재 포거스된 날짜
  DateTime? _selectedDay; //선택한 날짜
  late ValueNotifier<List<EventModel>> _selectedEvents;
  //선택한 날짜의 이벤트 목록
  bool _isLoading= true;

  void refreshCalendar() {
    setState(() {
      _fetchEvents();
    });
  }
  Map<String, String> categoryColors = {};

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('category').get();
      categoryColors = Map.fromEntries(
          snapshot.docs.map((doc) => MapEntry(doc.id, doc.data()['colorCode'] as String))
      );
      print('Loaded categories: $categoryColors'); // 로그 추가
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void initState() {
    super.initState(); // 위젯 처음 생성시 호출
    _selectedDay = _focusedDay; //// _selectedDay 초기화
    _selectedEvents = ValueNotifier<List<EventModel>>([]); // 빈목록으로 초기화 해 일정 가져옴
    _loadCategories().then((_) {
      updateExistingEvents().then((_) => _fetchEvents());
    });
  }



  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        final showOnCalendar = data['showOnCalendar'] as bool? ?? true;
        if (showOnCalendar) {
          final categoryId = data['categoryId'] as String?;
          final colorCode = categoryColors[categoryId];
          return EventModel.fromMap({...data, 'categoryColor': colorCode});
        }
        return null;
      }).whereType<EventModel>().toList();

      setState(() {
        kEvents = _groupEvents(events);
        _isLoading = false;
        _selectedEvents.value = _getEventsForDay(_selectedDay ?? DateTime.now());
      });
    } catch (error) {
      print('Error fetching events: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateExistingEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['categoryId'] == null || data['categoryId'] == '') {
          // 카테고리 ID가 없는 경우, 기본 카테고리 할당
          if (categoryColors.isNotEmpty) {
            batch.update(doc.reference, {'categoryId': categoryColors.keys.first});
          } else {
            print('No categories available to assign default category');
          }        }
      }

      await batch.commit();
      print('Updated existing events with default category');
    } catch (e) {
      print('Error updating existing events: $e');
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
    final filteredEvents = events.where((event) => event.showOnCalendar).toList();
    if (events.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final eventTitle = event.eventTitle;
        final displayTitle =
        eventTitle.length > 15 ? '${eventTitle.substring(0, 15)}…' : eventTitle;

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
    return Colors.grey; // 기본 색상
  }


  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {

      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents.value = _getEventsForDay(selectedDay);
    });

    // 선택한 날짜의 이벤트를 가져와서 DayEventsScreen으로 이동
    final selectedEvents = _getEventsForDay(selectedDay).where((event) => event.showOnCalendar).toList();

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
      ).then((_) async {
        await _fetchEvents();  // RootScreen에서 돌아온 후 데이터 갱신
        setState(() {
          _selectedEvents.value = _getEventsForDay(selectedDay);  // 선택된 날짜의 이벤트 갱신
        });
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
              markerBuilder: (context, day, events) {
                return SizedBox.shrink(); // 마커 빌더는 사용하지 않음
              },
              defaultBuilder: (context, day, focusedDay) {
                return Stack(
                  children: [
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(fontSize: 16,
                          color: day.weekday == DateTime.sunday ? Colors.red : Colors.black,),
                      ),
                    ),
                    Positioned.fill(
                      top: 25, // 날짜 아래에 위치하도록 조정
                      child: _buildEventsMarker(day, _getEventsForDay(day)),
                    ),
                  ],
                );
              },
              selectedBuilder: (context, day, focusedDay) {
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
                      child: _buildEventsMarker(day, _getEventsForDay(day)),
                    ),
                  ],
                );
              },

              todayBuilder: (context, day, focusedDay) {
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
                      child: _buildEventsMarker(day, _getEventsForDay(day)),
                    ),
                  ],
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return Stack(
                  children: [
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(fontSize: 16, color: day.weekday == DateTime.sunday ? Colors.red.withOpacity(0.5) : Colors.grey,),
                      ),
                    ),
                    Positioned.fill(
                      top: 25,
                      child: _buildEventsMarker(day, _getEventsForDay(day)),
                    ),
                  ],
                );
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

