import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/event_model.dart';
import '../services/event_service.dart';
import 'add_event_screen.dart';
import 'package:intl/intl.dart';

import 'day_events_screen.dart';

class CalendarScreen extends StatefulWidget {
  final Function? onEventUpdated;

  CalendarScreen({
    Key? key,
    this.onEventUpdated,
  }) : super(key: key);


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



  Map<String, String> categoryColors = {};

  Future<void> _loadCategories() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('category').get();
      categoryColors = Map.fromEntries(snapshot.docs
          .map((doc) => MapEntry(doc.id, doc.data()['colorCode'] as String)));
      print('Loaded categories: $categoryColors'); // 로그 추가
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void initState() {
    super.initState(); // 위젯 처음 생성시 호출
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      EventService().setUserId(user.uid);
    }
    _selectedDay = _focusedDay; //// _selectedDay 초기화
    _selectedEvents = ValueNotifier<List<EventModel>>([]); // 빈목록으로 초기화 해 일정 가져옴
    _loadCategories().then((_) {
      updateExistingEvents().then((_) => _fetchEvents());
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshCalendar();
  }

  Future<void> refreshCalendar() async {
    await _loadCategories();
    await _fetchEvents();
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _changeCalendarFormat() {
    setState(() {
      if (_calendarFormat == CalendarFormat.month) {
        _calendarFormat = CalendarFormat.twoWeeks;
      } else if (_calendarFormat == CalendarFormat.twoWeeks) {
        _calendarFormat = CalendarFormat.week;
      } else {
        _calendarFormat = CalendarFormat.month;
      }
    });
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: user!.uid)
          .where('showOnCalendar', isEqualTo: true)
          .get();

      if (!mounted) return;  // 추가: 비동기 작업 후 다시 한 번 확인

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String?;
        final colorCode = categoryColors[categoryId];
        print(
            'Event: ${data['eventTitle']}, CategoryID: $categoryId, ColorCode: $colorCode'); // 로그 추가
        return EventModel.fromMap({...data, 'categoryColor': colorCode});
      }).toList();

      if (mounted) {
        setState(() {
          kEvents = _groupEvents(events);

          _selectedEvents.value =
              _getEventsForDay(_selectedDay ?? DateTime.now());
        });
      }
    }catch (error) {
      print('Error fetching events: $error');

      if(mounted) {
        setState(() {

        });
      }


      setState(() {});
    }
  }

  List<EventModel> _getEventsForWeek(DateTime day) {
    final weekStart = day.subtract(Duration(days: day.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 7));

    return kEvents.entries
        .where((entry) =>
    entry.key.isAfter(weekStart.subtract(Duration(days: 1))) &&
        entry.key.isBefore(weekEnd))
        .expand((entry) => entry.value)
        .toList();
  }

  Widget _buildWeeklyEventList() {
    final weekEvents = _getEventsForWeek(_focusedDay);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: weekEvents.length,
      itemBuilder: (context, index) {
        final event = weekEvents[index];
        return ListTile(
          title: Text(event.eventTitle),
          subtitle:
          Text(DateFormat('yyyy-MM-dd HH:mm').format(event.eventDate!)),
        );
      },
    );
  }

  Future<void> updateExistingEvents() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('events').get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['categoryId'] == null || data['categoryId'] == '') {
          // 카테고리 ID가 없는 경우, 기본 카테고리 할당
          if (categoryColors.isNotEmpty) {
            batch.update(
                doc.reference, {'categoryId': categoryColors.keys.first});
          } else {
            print('No categories available to assign default category');
          }
        }
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
        event.eventDate?.year ?? 0,
        event.eventDate?.month ?? 0,
        event.eventDate?.day ?? 0,
      );
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
        final displayTitle = eventTitle.length > 15
            ? '${eventTitle.substring(0, 15)}…'
            : eventTitle;

        Color categoryColor = _getCategoryColor(event.categoryColor);
        Color backgroundColor = _getLighterColor(categoryColor);

        return Container(
          margin: EdgeInsets.only(bottom: 2, left: 2, right: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              displayTitle,
              style: TextStyle(color: categoryColor, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

// 선택한 색의 명도를 높이는 함수
//   Color _getLighterColor(Color color) {
//     final hslColor = HSLColor.fromColor(color);
//     return hslColor
//         .withLightness((hslColor.lightness + 0.4).clamp(0.0, 1.0))
//         .toColor();
//   }
  Color _getLighterColor(Color color) {
    // 먼저 색상이 검정색인지 확인
    if (color.value == 0xFF000000) {
      // 검정색인 경우 순수한 회색으로 변환
      return Color.fromRGBO(240, 240, 240, 1.0); // 밝은 회색
    }

    // 다른 색상들에 대해서는 기존 로직 적용
    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withSaturation(0.3)
        .withLightness((hslColor.lightness + 0.4).clamp(0.0, 1.0))
        .toColor();
  }


  Color _getCategoryColor(String? colorCode) {
    if (colorCode != null && colorCode.isNotEmpty) {
      try {
        // colorCode가 '0xFF'로 시작하는 경우 처리
        if (colorCode.startsWith('0x')) {
          return Color(int.parse(colorCode));
        }
        // '#'으로 시작하는 경우 처리
        return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
      } catch (e) {
        print('Error parsing color code: $colorCode');
      }
    }
    return Colors.black; // 기본 색상을 검정색으로 변경
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
      final selectedDateWithoutZ =
      selectedDay.toIso8601String().replaceAll('Z', '');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEventScreen(
            selectedDate: selectedDay,
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
          builder: (context) => DayEventsScreen(
            selectedDate: selectedDay,
            events: [],
            updateCalendar: () {},
          ),
        ),
      ).then((_) async {
        await _fetchEvents(); // RootScreen에서 돌아온 후 데이터 갱신
        setState(() {
          _selectedEvents.value =
              _getEventsForDay(selectedDay); // 선택된 날짜의 이벤트 갱신
        });
      });
    }
  }



  void _showMonthPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (index) => currentYear - 50 + index);
    final mainColor = Colors.lightBlue[900]!;
    final backgroundColor = Colors.grey[100]!;

    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '날짜 선택',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.white),
                        ],
                      ),
                    ),

                    // 년도 선택
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text('년도', style: TextStyle(color: Colors.grey[600])),
                          Container(
                            height: 150,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: years.indexOf(selectedYear),
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedYear = years[index];
                                });
                              },
                              children: years.map((year) => Center(
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 월 선택 그리드
                    Container(
                      height: 280,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == selectedMonth;
                          final monthName = '${month}월';

                          return GestureDetector(
                            onTap: () {
                              final selectedDate = DateTime(selectedYear, month);
                              Navigator.pop(context);
                              this.setState(() {
                                _focusedDay = selectedDate;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? mainColor : backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? mainColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  monthName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 버튼 영역
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final selectedDate =
                              DateTime(selectedYear, selectedMonth);
                              Navigator.pop(context);
                              this.setState(() {
                                _focusedDay = selectedDate;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final availableHeight = constraints.maxHeight;
          //inal calculatedRowHeight = (availableHeight - kToolbarHeight - MediaQuery.of(context).padding.top) / 6;
          // 캘린더의 기본 rowHeight 계산
          double rowHeight = (availableHeight-100) / 5;

          // 조건: 캘린더의 이벤트가 많을 때 rowHeight를 줄이기
          if (_selectedEvents.value.length > 5) {
            rowHeight *= 0.8; // 줄이기 비율을 조정 가능
          }
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: TableCalendar<EventModel>(
                        locale: 'ko_KR',
                        firstDay: DateTime.utc(2010, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        availableGestures: AvailableGestures.none,
                        calendarStyle: CalendarStyle(
                          cellMargin: EdgeInsets.zero,
                          tableBorder: TableBorder.all(
                            color: Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                        availableCalendarFormats: {
                          CalendarFormat.month: '월',
                          CalendarFormat.twoWeeks: '2주',
                          CalendarFormat.week: '주',
                        },
                        sixWeekMonthsEnforced: true,
                        rowHeight: rowHeight,
                        onFormatChanged: _onFormatChanged,

                        daysOfWeekHeight: 40,
                        eventLoader: _getEventsForDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: day.weekday == DateTime.sunday
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  top: 25, // 날짜 아래에 위치하도록 조정
                                  child: _buildEventsMarker(
                                      day, _getEventsForDay(day)),
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
                                      border: Border.all(
                                          color: Colors.green, width: 1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: Text(
                                    day.day.toString(),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green),
                                  ),
                                ),
                                Positioned.fill(
                                  top: 25,
                                  child: _buildEventsMarker(
                                      day, _getEventsForDay(day)),
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
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.blue),
                                  ),
                                ),
                                Positioned.fill(
                                  top: 25,
                                  child: _buildEventsMarker(
                                      day, _getEventsForDay(day)),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: day.weekday == DateTime.sunday
                                          ? Colors.red.withOpacity(0.5)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  top: 25,
                                  child: _buildEventsMarker(
                                      day, _getEventsForDay(day)),
                                ),
                              ],
                            );
                            //   child: Text(
                            //     day.day.toString(),
                            //     style: TextStyle(color: Colors.grey),
                            //   ),
                            // );
                          },
                        ),
                        onHeaderTapped: (_) => _showMonthPicker(),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          headerPadding: EdgeInsets.symmetric(vertical: 4),
                          // 수직 패딩 줄이기
                          headerMargin: EdgeInsets.zero,
                          // 하단 마진 줄이기
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextFormatter: (date, locale) =>
                              DateFormat.yMMM(locale).format(date),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue[900],
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),  // 추가
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),  // 추가
                        ),
                      )),
                  if (_calendarFormat != CalendarFormat.month)
                    _buildWeeklyEventList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
