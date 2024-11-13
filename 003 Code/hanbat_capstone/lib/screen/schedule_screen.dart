
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanbat_capstone/screen/time_range_setting_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import '../component/date_selector.dart';
import '../component/time_cell.dart';
import '../component/event_cell.dart';
import '../component/checkbox_component.dart';
import '../providers/category_provider.dart';
import '../providers/schedulesettings_provider.dart';
import '../services/event_service.dart';
import 'add_event_screen.dart';
import 'calendar_screen.dart';
import 'event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
export 'schedule_screen.dart' show ScheduleScreenState;

class ScheduleScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Function? onEventUpdated;  // 콜백 추가

  ScheduleScreen({
    Key? key,
    required this.selectedDate,
    this.onEventUpdated,
  }) : super(key: key);

  @override
  State<ScheduleScreen> createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  late String formattedDate;
  Map<String, List<Map<String, String>>> scheduleData = {};
  int startTime = 0;
  int endTime = 23;
  Map<int, bool> selectedStates = {};
  Map<String, bool> allDayEventStates = {};
  final EventService eventService = EventService();
  late DateTime _focusedDate;
  late PageController _pageController;
  int _currentPage = 5000;
  List<EventModel> allDayEvents = [];
  List<EventModel> regularEvents = [];
  List<EventResultModel> regularResultEvents = [];
  bool _isLoading = true;
  List<EventResultModel> resultEvents = [];
  Map<String, String> categoryColors = {};  // 카테고리 색상 정보를 저장할 맵 추가
  bool _mounted = true;

  final Color dragSourceColor = Colors.blue.withOpacity(0.1); // 원본 위치 색상
  final Color dragFeedbackColor = Colors.blue.withOpacity(0.1); // 드래그 중인 아이템 색상
  final Color dragTargetColor = Colors.green.withOpacity(0.1); // 드롭 대상 영역 색상
  final Color dragTargetActiveColor = Colors.green.withOpacity(0.2); // 드래그 오버 시 색상

  Future<void> refreshSchedule() async {
    await _loadInitialData();
    widget.onEventUpdated?.call();  // 상위 위젯에 알림
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
  void setState(VoidCallback fn) {
    if (_mounted && mounted) {
      super.setState(fn);
    }
  }
  // 비동기 작업에서 setState 호출 시
  Future<void> someAsyncFunction() async {
    if (!_mounted || !mounted) return;
    // ... 작업 수행
    setState(() {
      // 상태 업데이트
    });
  }

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate ?? DateTime.now();
    formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
    _pageController = PageController(initialPage: 1000);

    _ensureUserLoggedIn();
    _initializeScreen();
  }


  Future<void> _initializeScreen() async {
    if (!mounted) return;

    await _ensureUserLoggedIn();
    await _loadInitialData();

    // CategoryProvider 초기화
    if (mounted) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.loadCategories();
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 카테고리 데이터 먼저 로드
      await _loadCategories();

      // 다른 데이터 로드
      await Future.wait([
        _loadSettings(),
        _loadAllDayEventStates(),
      ]);

      // 이벤트 로드 전에 카테고리 색상이 있는지 확인
      if (categoryColors.isEmpty) {
        print('Warning: Categories not loaded properly');
        // 카테고리 다시 로드 시도
        await _reloadCategories();
      }

      await _loadEvents();
    } catch (e) {
      print('Error in _loadInitialData: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadCategories() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        categoryColors = Map.fromEntries(
            snapshot.docs.map((doc) => MapEntry(
                doc.id,
                doc.data()['colorCode'] as String? ?? '0xFF000000'
            ))
        );
      });

      // CategoryProvider에도 동기화
      if (mounted) {
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.loadCategories();
      }
    } catch (e) {
      print('Error reloading categories: $e');
    }
  }
// 카테고리 로드 함수 수정
  Future<void> _loadCategories() async {
    if (!mounted) return;  // 추가: mounted 체크

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (!mounted) return;

      final newCategories = <String, String>{};
      for (var doc in snapshot.docs) {
        final colorCode = doc.data()['colorCode'] as String;
        newCategories[doc.id] = colorCode;
        print('Loaded category: ${doc.id} with color: $colorCode');
      }

      if (mounted) {  // 추가: mounted 체크
        setState(() {
          categoryColors = newCategories;
        });
      }

      print('Categories loaded successfully. Total: ${categoryColors.length}');
      return;

    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final allEvents = await eventService.getEventsForDate(_focusedDate);
      final regularResultEvents = await eventService.getResultEventsForDate(
          _focusedDate, excludeAllDay: true);

      setState(() {
        allDayEvents = allEvents.where((event) => event.isAllDay).toList();
        regularEvents = allEvents.where((event) => !event.isAllDay).toList();
        this.regularResultEvents = regularResultEvents;
        _updateScheduleData();
      });
    } catch (e) {
      print('Error loading events: $e');
      // 에러 처리
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _updateScheduleData() {
    scheduleData[formattedDate] = eventService.generateScheduleData(
      _focusedDate,
      startTime,
      endTime,
      regularEvents,
      regularResultEvents,
    );
  }

  Future<void> _loadAllDayEventStates() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('allDayEventStates')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: formattedDate)
          .get();

      setState(() {
        allDayEventStates = Map.fromEntries(
            snapshot.docs.map((doc) =>
                MapEntry(doc['eventId'] as String, doc['isCompleted'] as bool))
        );
      });
    } catch (e) {
      print('Error loading all-day event states: $e');
    }
  }

  Future<void> _saveAllDayEventState(String eventId, bool isCompleted) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('allDayEventStates')
          .doc('${userId}_${formattedDate}_$eventId')
          .set({
        'userId': userId,
        'date': formattedDate,
        'eventId': eventId,
        'isCompleted': isCompleted,
      });
    } catch (e) {
      print('Error saving all-day event state: $e');
    }
  }

  Future<void> _handleAllDayEventCheckboxChange(String eventId,
      bool newValue) async {
    try {
      await eventService.updateAllDayEventState(
          formattedDate, eventId, newValue);
      setState(() {
        allDayEventStates[eventId] = newValue;
      });


      // 상태 변경 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? '종일 일정이 완료되었습니다.'
              : '종일 일정 완료가 취소되었습니다.'),
        ),
      );
    } catch (e) {
      print('Error handling all-day event checkbox change: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('종일 일정 상태 변경 중 오류가 발생했습니다.')),
      );
      setState(() {
        allDayEventStates[eventId] = !newValue;
      });
    }
  }

  Widget _buildAllDayEventsSection() {
    if (allDayEvents.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.lightBlue[900], size: 20),
                SizedBox(width: 8),
                Text(
                  '종일 일정',
                  style: TextStyle(
                    color: Colors.lightBlue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allDayEvents.length,
            itemBuilder: (context, index) {
              final event = allDayEvents[index];
              final isCompleted = allDayEventStates[event.eventId] ?? false;
              final categoryColor = event.categoryId != null && categoryColors.containsKey(event.categoryId)
                  ? _getCategoryColor(categoryColors[event.categoryId])
                  : Colors.lightBlue[900]!;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: index != allDayEvents.length - 1
                        ? BorderSide(color: Colors.grey[300]!)
                        : BorderSide.none,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleAllDayEventTap(event),
                    onDoubleTap: () => _openEventDetail(event.eventTitle, index, isplan: true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event.eventTitle,
                              style: TextStyle(
                                fontSize: 15,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted ? Colors.transparent : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: isCompleted ? categoryColor : Colors.transparent,
                            ),
                            child: isCompleted
                                ? Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? colorCode) {
    if (colorCode != null && colorCode.isNotEmpty) {
      try {
        // colorCode가 '0xFF'로 시작하는 경우 처리
        if (colorCode.startsWith('0x')) {
          return Color(int.parse(colorCode));
        }
        // '#'으로 시작하는 경우 처리
        else if (colorCode.startsWith('#')) {
          return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
        }
        // 다른 형식의 colorCode 처리
        return Color(int.parse('0xFF${colorCode.replaceAll("#", "")}'));
      } catch (e) {
        print('Error parsing color code: $colorCode');
        return Colors.lightBlue[900]!;
      }
    }
    return Colors.lightBlue[900]!; // 기본 색상
  }


// 힌트 메시지를 보여주는 함수 추가
  void _showEventDetailHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('더블 탭하여 일정 상세 정보를 확인하세요'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

// 기존 _handleAllDayEventTap 함수 수정
  void _handleAllDayEventTap(EventModel event) async {
    // 이전의 완료 상태 토글 로직은 유지하면서 힌트 메시지 추가
    final newState = !(allDayEventStates[event.eventId] ?? false);
    setState(() {
      allDayEventStates[event.eventId] = newState;
    });
    await _saveAllDayEventState(event.eventId, newState);
    await _handleAllDayEventCheckboxChange(event.eventId, newState);

    // 힌트 메시지 표시
    _showEventDetailHint();
  }


  Future<void> _ensureUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 로그인 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      eventService.setUserId(user.uid);
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        startTime = prefs.getInt('startTime') ?? 0;
        endTime = prefs.getInt('endTime') ?? 24;
      });
      _initScheduleList();
      await _fetchEvents();
      await _loadCheckboxStates();
    } catch (e) {
      print('Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정을 불러오는 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initScheduleList() {
    scheduleData[formattedDate] = List.generate(
      endTime - startTime + 1,
          (_) => {'plan': '', 'actual': ''},
    );
  }

// 이 import 문을 파일 상단에 추가해주세요.
//
//   Future<void> _fetchEvents() async {
//     setState(() => _isLoading = true);
//     try {
//       print("Fetching events for date: ${_focusedDate.toIso8601String()}");
//       final events = await eventService.getEventsForDate(_focusedDate);
//       var resultEvents = await eventService.getResultEventsForDate(_focusedDate);
//       final fetchedResultEvents = await eventService.getResultEventsForDate(_focusedDate);
//       print("Fetched ${events.length} events and ${resultEvents.length} result events");
//
//       setState(() {
//         allDayEvents = events.where((event) => event.isAllDay).toList();
//         regularEvents = events.where((event) => !event.isAllDay).toList();
//         resultEvents = fetchedResultEvents;
//         scheduleData[formattedDate] = List.generate(
//           endTime - startTime + 1,
//               (index) {
//             final hour = startTime + index;
//             final planEvents = regularEvents.where((event) {
//               return event.eventSttTime!.hour <= hour && event.eventEndTime!.hour > hour;
//             }).toList();
//             final actualEvents = resultEvents.where((event) {
//               return event.eventResultSttTime!.hour <= hour && event.eventResultEndTime!.hour > hour;
//             }).toList();
//
//             return {
//               'plan': planEvents.isNotEmpty ? planEvents.first.eventTitle : '',
//               'planCategoryId': planEvents.isNotEmpty ? planEvents.first.categoryId : '',
//               'actual': actualEvents.isNotEmpty ? actualEvents.first.eventResultTitle : '',
//               'actualCategoryId': actualEvents.isNotEmpty ? actualEvents.first.categoryId : '',
//               'completedYn': planEvents.isNotEmpty ? planEvents.first.completedYn ?? 'N' : 'N',
//               'eventId': planEvents.isNotEmpty ? planEvents.first.eventId : '',
//             };
//           },
//         );
//
//         // 체크박스 상태 업데이트
//         for (int i = startTime; i <= endTime; i++) {
//           selectedStates[i] = resultEvents.any((event) =>
//           event.eventResultSttTime!.hour <= i && event.eventResultEndTime!.hour > i
//           );
//         }
//       });
//     } catch (e) {
//       print('Error fetching events: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('일정을 불러오는 중 오류가 발생했습니다.')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(
          _focusedDate.year, _focusedDate.month, _focusedDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      print("Fetching events for date: ${startOfDay
          .toIso8601String()} to ${endOfDay.toIso8601String()}");

      final events = await eventService.getEventsForDate(startOfDay);
      final fetchedResultEvents = await eventService.getResultEventsForDate(
          startOfDay);

      print("Fetched ${events.length} events and ${fetchedResultEvents
          .length} result events");

      if (!mounted) return;  // 위젯이 dispose된 경우 중단

      setState(() {
        allDayEvents =
            events.where((event) => event.isAllDay ?? false).toList();
        regularEvents =
            events.where((event) => !(event.isAllDay ?? false)).toList();
        resultEvents = fetchedResultEvents;

        allDayEventStates = {
          for (var event in allDayEvents)
            event.eventId: event.completedYn == 'Y'
        };

        scheduleData[formattedDate] = List.generate(
          25, // 0시부터 24시까지 (25개의 시간대)
              (hour) {
            final planEvents = regularEvents.where((event) {
              if (event.isAllDay ?? false) return false;
              final eventStartHour = event.eventSttTime!.hour;
              final eventEndHour = event.eventEndTime!.hour == 0 ? 24 : event
                  .eventEndTime!.hour;
              return eventStartHour <= hour && hour < eventEndHour;
            }).toList();

            final actualEvents = resultEvents.where((event) {
              if (event.isAllDay ?? false) return false;
              final eventStartHour = event.eventResultSttTime!.hour;
              final eventEndHour = event.eventResultEndTime!.hour == 0
                  ? 24
                  : event.eventResultEndTime!.hour;
              return eventStartHour <= hour && hour < eventEndHour;
            }).toList();

            return {
              'plan': planEvents.isNotEmpty ? planEvents.first.eventTitle : '',
              'planCategoryId': planEvents.isNotEmpty ? planEvents.first
                  .categoryId : '',
              'actual': actualEvents.isNotEmpty ? actualEvents.first
                  .eventResultTitle : '',
              'actualCategoryId': actualEvents.isNotEmpty ? actualEvents.first
                  .categoryId : '',
              'completedYn': planEvents.isNotEmpty ? planEvents.first
                  .completedYn ?? 'N' : 'N',
              'eventId': planEvents.isNotEmpty ? planEvents.first.eventId : '',
            };
          },
        );

        for (int hour = 0; hour <= 24; hour++) {
          selectedStates[hour] = resultEvents.any((event) {
            if (event.isAllDay ?? false) return false;
            final eventStartHour = event.eventResultSttTime!.hour;
            final eventEndHour = event.eventResultEndTime!.hour == 0
                ? 24
                : event.eventResultEndTime!.hour;
            return eventStartHour <= hour && hour < eventEndHour;
          });
        }
      });

      await _loadAllDayEventStates();
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 불러오는 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int page) {
    final newDate = DateTime(_focusedDate.year, _focusedDate.month,
        _focusedDate.day + (page - 1000));
    if (newDate != _focusedDate) {
      setState(() {
        _focusedDate = newDate;
        formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
      });
      _initScheduleList();
      _fetchEvents();
      _loadCheckboxStates();
    }
  }

  void _updateDate(int daysOffset) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: daysOffset));
      formattedDate = DateFormat('yyyy-MM-dd').format(_focusedDate);
      _initScheduleList();
    });
    _fetchEvents();
    _loadCheckboxStates();
  }

  Future<void> _loadCheckboxStates() async {
    final states =
    await eventService.loadTimeBasedCheckboxStatesForDate(formattedDate);
    setState(() {
      selectedStates = states;
    });
  }

  void _handleCheckboxChange(int hour, bool newValue) async {
    print("Checkbox changed for hour: $hour");
    try {
      final eventResultId = scheduleData[formattedDate]?[hour -
          startTime]?['eventResultId'];
      if (eventResultId != null) {
        await eventService.updateResultEventCompleteStatus(
            eventResultId, newValue);
        setState(() {
          scheduleData[formattedDate]![hour - startTime]['completeYn'] =
          newValue ? 'Y' : 'N';
        });
      }
      final eventForHour = regularEvents.firstWhereOrNull((event) {
        final eventEndHour = event.eventEndTime!.hour == 0 ? 24 : event
            .eventEndTime!.hour;
        return event.eventSttTime!.hour <= hour && eventEndHour > hour;
      });

      if (eventForHour != null) {
        final newState = !(selectedStates[hour] ?? false);
        setState(() {
          selectedStates[hour] = newState;
          if (hour == 24 && eventForHour.eventEndTime!.hour == 0) {
            selectedStates[0] = newState;
          }
        });

        if (newState) {
          print("Moving plan to actual for hour: $hour");
          await eventService.movePlanToActual(
              formattedDate, hour, eventForHour);
        } else {
          print("Updating result event for hour: $hour");
          await eventService.removeResultEvent(
              formattedDate, hour, eventForHour.eventId);
        }

        // 상태 업데이트 후 이벤트와 체크박스 상태 다시 로드
        print("Fetching events and loading checkbox states");
        await _fetchEvents();

        // 상태 변경 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newState
                  ? '$hour:00 시간대가 완료되었습니다.'
                  : '$hour:00 시간대 완료가 취소되었습니다.')),
        );
      }
    } catch (e) {
      print('Error handling checkbox change: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 상태 변경 중 오류가 발생했습니다.')),
      );
    }
  }


  void _handlePlanCellTap(int index) async {
    print("Plan cell tapped at index: $index"); // 디버그
    final eventTitle = scheduleData[formattedDate]?[index]['plan'];
    if (eventTitle == null || eventTitle.isEmpty) {
      _addNewEvent(index);
    } else {
      _openEventDetail(eventTitle, index, isplan: true);
    }
  }

  void _handleActualCellTap(int index) async {
    final eventTitle = scheduleData[formattedDate]?[index]['actual'];
    if (eventTitle == null || eventTitle.isEmpty) {
      _addNewResultEvent(index);
    } else {
      _openEventDetail(eventTitle, index, isplan: false);
    }
  }

  void _addNewEvent(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEventScreen(
              selectedDate: _focusedDate,
              selectedTime: DateTime(
                _focusedDate.year,
                _focusedDate.month,
                _focusedDate.day,
                startTime + index,
              ),
            ),
      ),
    ).then((_) => _fetchEvents());
  }

  void _addNewResultEvent(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEventScreen(
              selectedDate: _focusedDate,
              selectedTime: DateTime(
                _focusedDate.year,
                _focusedDate.month,
                _focusedDate.day,
                startTime + index,
              ),
              isFinalEvent: true,
            ),
      ),
    ).then((_) => _fetchEvents());
  }

  void _openEventDetail(String eventTitle, int index,
      {required bool isplan}) async {
    print("Opening event detail for: $eventTitle, isplan: $isplan");

    final eventDate =
    DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);

    print("Querying Firestore for event on $eventDate");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(isplan ? 'events' : 'result_events')
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isGreaterThanOrEqualTo: eventDate.toUtc().toIso8601String())
          .where(isplan ? 'eventDate' : 'eventResultDate',
          isLessThan:
          eventDate.add(Duration(days: 1)).toUtc().toIso8601String())
          .get();

      print("Firestore query result: ${snapshot.docs.length} documents");

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          print("Found event: ${doc.data()}");
        }

        // 제목이 일치하는 이벤트 찾기
        final matchingEvent = snapshot.docs.firstWhere(
              (doc) =>
          doc.get(isplan ? 'eventTitle' : 'eventResultTitle') == eventTitle,
        );

        if (matchingEvent != null) {
          final event = isplan
              ? EventModel.fromMap(matchingEvent.data())
              : EventResultModel.fromMap(matchingEvent.data());

          print("Matching event found: ${event.toString()}");

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EventDetailScreen(
                    event: isplan ? event as EventModel : null,
                    eventResult: isplan ? null : event as EventResultModel,
                    selectedDate: _focusedDate,
                    updateCalendar: () async {
                      await _loadInitialData();  // 전체 데이터 새로고침
                      widget.onEventUpdated?.call();  // 일정 업데이트 시 콜백 호출
                    },
                    onEventDeleted: (deleteAllRecurrence) async {
                      if (isplan) {
                        await eventService.deleteEvent((event as EventModel).eventId);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('result_events')
                            .doc((event as EventResultModel).eventResultId)
                            .delete();
                      }
                      _fetchEvents();
                    },
                    onEventEdited: (editedEvent) async {
                      if (editedEvent != null) {
                        await FirebaseFirestore.instance
                            .collection(isplan ? 'events' : 'result_events')
                            .doc(isplan
                            ? (event as EventModel).eventId
                            : (event as EventResultModel).eventResultId)
                            .update(editedEvent.toMap());

                        setState(() {
                          if (isplan) {
                            final updatedEvent = EventModel(
                              eventId: editedEvent.eventId,
                              eventTitle: editedEvent.eventTitle,
                              eventDate: editedEvent.eventDate,
                              eventSttTime: editedEvent.eventSttTime,
                              eventEndTime: editedEvent.eventEndTime,
                              eventContent: editedEvent.eventContent,
                              categoryId: editedEvent.categoryId,
                              userId: editedEvent.userId,
                              isAllDay: editedEvent.isAllDay,
                              completedYn: editedEvent.completedYn,
                              isRecurring: editedEvent.isRecurring,
                              showOnCalendar: editedEvent.showOnCalendar,
                              originalEventId: editedEvent.originalEventId,
                            );
                            // 기존 이벤트를 새로운 이벤트로 교체
                            final eventIndex = regularEvents.indexWhere((e) =>
                            e.eventId == updatedEvent.eventId);
                            if (eventIndex != -1) {
                              regularEvents[eventIndex] = updatedEvent;
                            }
                          } else {
                            // EventResultModel에 대한 처리
                          }
                        });
                        await _loadInitialData();  // 전체 데이터 새로고침

                        widget.onEventUpdated?.call();  // 화면으로 돌아왔을 때도 콜백 호출
                      }
                    },
                  ),
            ),
          );

          await _loadInitialData();  // 화면으로 돌아왔을 때도 새로고침
          widget.onEventUpdated?.call();  // 상위 위젯에 알림
        } else {
          print("No matching event found for title: $eventTitle");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일치하는 이벤트를 찾을 수 없습니다.')),
          );
        }
      } else {
        print("No events found for the given date");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해당 날짜에 이벤트가 없습니다.')),
        );
      }
    } catch (e) {
      print("Error querying Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 조회 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<ScheduleSettingsProvider>();
    final startTime = settings.startTime;
    final endTime = settings.endTime;
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: DateSelector(
          selectedDate: _focusedDate,
          onDateChanged: (date) {
            setState(() {
              _focusedDate = date;
            });
            _fetchEvents();
            _initScheduleList();
            _pageController.jumpToPage(1000); // Reset to the middle page
            _loadCheckboxStates();
          },
          onPreviousDay: () =>
              _pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
          onNextDay: () =>
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
        ),

        elevation: 0,
      ),
      body: Column(
        children: [

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageDate = _focusedDate.add(
                    Duration(days: index - _currentPage));
                return _buildPageContent(pageDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(DateTime pageDate) {
    return Column(
      children: [
        _buildAllDayEventsSection(),
        Expanded(
          child: _buildRegularEventsSection(pageDate),
        ),
      ],
    );
  }

  Widget _buildTimeBlock(int hour, DateTime pageDate) {
    final timeData = scheduleData[formattedDate]?[hour - startTime] ??
        {'plan': '', 'actual': ''};

    String planTitle = timeData['plan'] ?? '';
    String actualTitle = timeData['actual'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                  hour == 24 ? '24:00' : '${hour.toString().padLeft(2, '0')}:00'
              ),
            ),
            Expanded(
              flex: 2,
              child: Draggable<Map<String, dynamic>>(
                data: {
                  'eventTitle': planTitle,
                  'categoryId': timeData['planCategoryId'] ?? '',
                  'hour': hour,
                  'eventId': timeData['eventId'] ?? '',
                },
                feedback: Material(
                  elevation: 4.0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dragFeedbackColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: Text(
                      planTitle,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: EventCell(
                    eventTitle: planTitle,
                    categoryId: timeData['planCategoryId'] ?? '',
                    onTap: () => _handlePlanCellTap(hour - startTime),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dragSourceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: EventCell(
                    eventTitle: planTitle,
                    categoryId: timeData['planCategoryId'] ?? '',
                    onTap: () => _handlePlanCellTap(hour - startTime),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: DragTarget<Map<String, dynamic>>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? dragTargetActiveColor
                          : dragTargetColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: EventCell(
                      eventTitle: actualTitle,
                      categoryId: timeData['actualCategoryId'] ?? '',
                      onTap: () => _handleActualCellTap(hour - startTime),
                    ),
                  );
                },
                onAccept: (data) async {
                  final eventHour = data['hour'] as int;
                  final eventId = data['eventId'] as String;
                  if (eventId.isNotEmpty) {
                    try {
                      await eventService.movePlanToActual(
                        formattedDate,
                        hour,
                        regularEvents.firstWhere((e) => e.eventId == eventId),
                      );
                      _loadEvents(); // 화면 새로고침
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '계획된 일정이 실제 수행 목록으로 이동되었습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          elevation: 4,
                          action: SnackBarAction(
                            label: '확인',
                            textColor: Colors.white70,
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Error moving event: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '일정 이동 중 문제가 발생했습니다. 다시 시도해 주세요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          elevation: 4,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildEventCell(String eventTitle, String categoryId,
        VoidCallback onTap, Color backgroundColor) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: EventCell(
            eventTitle: eventTitle,
            categoryId: categoryId,
            onTap: onTap,
          ),
        ),
      );
    }

    // Widget _buildAllDayEventsSection() {
    //   if (allDayEvents.isEmpty) {
    //     return SizedBox.shrink(); // 종일 일정이 없으면 이 섹션을 표시하지 않음
    //   }
    //   return Container(
    //     color: Colors.grey[200],
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Padding(
    //           padding: const EdgeInsets.all(8.0),
    //           child: Text(
    //             '종일 일정',
    //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    //           ),
    //         ),
    //         ListView.builder(
    //           shrinkWrap: true,
    //           physics: NeverScrollableScrollPhysics(),
    //           itemCount: allDayEvents.length,
    //           itemBuilder: (context, index) {
    //             final event = allDayEvents[index];
    //             return ListTile(
    //               title: Text(event.eventTitle),
    //               subtitle: Text('종일'),
    //               onTap: () =>
    //                   _openEventDetail(event.eventTitle, index, isplan: true),
    //             );
    //           },
    //         ),
    //       ],
    //     ),
    //   );
    // }

    Widget _buildRegularEventsSection(DateTime pageDate) {
      return ListView.builder(
        itemCount: endTime - startTime , // 24시까지 표시하기 위해 25로 변경
        itemBuilder: (context, index) {
          return _buildTimeBlock(index + startTime, pageDate);
        },
      );
    }
  }


