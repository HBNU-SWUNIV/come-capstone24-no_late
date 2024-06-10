import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/Schedule_CRUD.dart';
import 'package:intl/intl.dart';
import 'package:hanbat_capstone/model/event_model.dart';
import 'package:hanbat_capstone/model/event_result_model.dart';
import 'package:hanbat_capstone/screen/add_event_screen.dart';
import 'package:hanbat_capstone/screen/envet_detail_screen.dart';

class schedule_screen extends StatelessWidget {
  final DateTime selectedDate;

  schedule_screen({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimeListView(selectedDate: selectedDate),
    );
  }
}

class TimeListView extends StatefulWidget {
  final DateTime selectedDate;

  TimeListView({required this.selectedDate});
  @override
  _TimeListViewState createState() => _TimeListViewState();
}

class _TimeListViewState extends State<TimeListView> {
  late DateTime selectedDate;

  final List<String> timeList = List.generate(24, (index) {
    return '${index.toString().padLeft(2, '0')}:00';
  });

  List<EventModel> scheduleList = List.generate(24, (_) => EventModel(
    eventId: '',
    categoryId: '',
    userId: '',
    eventTitle: '',
    allDayYn: 'N',
  ));

  List<EventResultModel> resultList = List.generate(24, (_) => EventResultModel(
    eventResultId: '',
    eventId: '',
    categoryId: '',
    userId: '',
    eventResultDate: DateTime.now(),
    eventResultSttTime: DateTime.now(),
    eventResultEndTime: DateTime.now(),
    eventResultTitle: '',
    eventResultContent: '',
    completeYn: 'N',
  ));

  List<bool> _isChecked = List.generate(24, (_) => false);

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _loadSchedules();
    _loadResults();
  }

  Future<void> _loadSchedules() async {
    try {
      final selectedDate = DateTime(this.selectedDate.year, this.selectedDate.month, this.selectedDate.day);
      final selectedDateStart = Timestamp.fromDate(selectedDate);
      final selectedDateEnd = Timestamp.fromDate(selectedDate.add(Duration(days: 1)).subtract(Duration(milliseconds: 1)));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('eventDate', isGreaterThanOrEqualTo: selectedDateStart)
          .where('eventDate', isLessThanOrEqualTo: selectedDateEnd)
          .get();

      final schedules = querySnapshot.docs.map((doc) {
        final eventData = doc.data();
        return EventModel(
          eventId: doc.id,
          categoryId: eventData['categoryId'],
          userId: eventData['userId'],
          eventDate: (eventData['eventDate'] as Timestamp?)?.toDate(),
          eventSttTime: (eventData['eventSttTime'] as Timestamp?)?.toDate(),
          eventEndTime: (eventData['eventEndTime'] as Timestamp?)?.toDate(),
          eventTitle: eventData['eventTitle'],
          eventContent: eventData['eventContent'],
          allDayYn: eventData['allDayYn'],
        );
      }).toList();

      setState(() {
        scheduleList = List.generate(24, (index) {
          final time = timeList[index];
          final matchingSchedules = schedules.where((schedule) {
            final eventTime = DateFormat('HH:mm').format(schedule.eventSttTime ?? DateTime.now());
            return eventTime == time;
          }).toList();

          if (matchingSchedules.isNotEmpty) {
            return matchingSchedules.first;
          } else {
            return EventModel(
              eventId: '',
              categoryId: '',
              userId: '',
              eventTitle: '',
              allDayYn: 'N',
            );
          }
        });
      });
    } catch (e) {
      print('Error loading schedules: $e');
      // 에러 처리 로직 추가
    }
  }

  Future<void> _loadResults() async {
    try {
      final results = await Schedule_CRUD.getEventResultsByDate(selectedDate);
      setState(() {
        resultList = List.generate(24, (index) {
          final time = timeList[index];
          final matchingResults = results.where((result) {
            final resultTime = DateFormat('HH:mm').format(result.eventResultSttTime);
            return resultTime == time;
          }).toList();

          if (matchingResults.isNotEmpty) {
            return matchingResults.first;
          } else {
            return EventResultModel(
              eventResultId: '',
              eventId: '',
              categoryId: '',
              userId: '',
              eventResultDate: selectedDate,
              eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
              eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
              eventResultTitle: '',
              eventResultContent: '',
              completeYn: 'N',
            );
          }
        });
      });
    } catch (e) {
      print('Error loading results: $e');
      // 에러 처리 로직 추가
    }
  }

  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
      _isChecked = List.generate(24, (_) => false);
      _loadSchedules();
      _loadResults();
    });
  }

  void _addSchedule(int index) async {
    final eventModel = scheduleList[index];
    if (eventModel.eventTitle.isEmpty) {
      // 계획이 비어있는 경우 AddEventScreen 띄우기
      final newEvent = await Navigator.push<EventModel>(
        context,
        MaterialPageRoute(builder: (context) => AddEventScreen(selectedDate: selectedDate)),
      );
      if (newEvent != null) {
        // AddEventScreen에서 입력된 데이터를 Firestore에 추가
        final eventRef = FirebaseFirestore.instance.collection('events').doc();
        await eventRef.set({
          'eventId': eventRef.id,
          'categoryId': newEvent.categoryId,
          'userId': newEvent.userId,
          'eventDate': newEvent.eventDate,
          'eventSttTime': newEvent.eventSttTime,
          'eventEndTime': newEvent.eventEndTime,
          'eventTitle': newEvent.eventTitle,
          'eventContent': newEvent.eventContent,
          'allDayYn': newEvent.allDayYn,
        });
        _loadSchedules(); // 일정 리스트 갱신
      }
    } else {
      // 계획이 비어있지 않은 경우 EventDetailScreen 띄우기
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailScreen(
          event: eventModel,
          onEventDeleted: (bool deleteAllRecurrence) async {
            if (deleteAllRecurrence) {
              // 모든 반복 일정 삭제
              await FirebaseFirestore.instance
                  .collection('events')
                  .where('eventId', isEqualTo: eventModel.eventId)
                  .get()
                  .then((snapshot) {
                for (DocumentSnapshot doc in snapshot.docs) {
                  doc.reference.delete();
                }
              });
            } else {
              // 현재 일정만 삭제
              await FirebaseFirestore.instance.collection('events').doc(eventModel.eventId).delete();
            }
            _loadSchedules(); // 일정 리스트 갱신
          },
          onEventEdited: (editedEvent) async {
            await FirebaseFirestore.instance.collection('events').doc(eventModel.eventId).update({
              'eventTitle': editedEvent.eventTitle,
              'eventContent': editedEvent.eventContent,
              // 수정된 다른 필드들도 업데이트
            });
            _loadSchedules(); // 일정 리스트 갱신
          },
        )),
      );
    }
  }

  void _add_actually_Schedule(int index) async {
    final eventResult = resultList[index];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String eventResultTitle = eventResult.eventResultTitle;
        String eventResultContent = eventResult.eventResultContent;

        return AlertDialog(
          title: const Text('일정 결과 추가/수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '결과 제목'),
                controller: TextEditingController(text: eventResultTitle),
                onChanged: (value) {
                  eventResultTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: '결과 내용'),
                controller: TextEditingController(text: eventResultContent),
                onChanged: (value) {
                  eventResultContent = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'eventResultTitle': eventResultTitle,
                  'eventResultContent': eventResultContent,
                });
              },
              child: const Text('저장'),
            ),
            if (eventResult.eventResultId.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await Schedule_CRUD.deleteEventResult(eventResult);
                  _loadResults();
                  Navigator.of(context).pop();
                },
                child: const Text('삭제'),
              ),
          ],
        );
      },
    );

    if (result != null) {
      if (eventResult.eventResultId.isNotEmpty) {
        // 기존 결과 수정
        final updatedEventResult = eventResult.copyWith(
          eventResultTitle: result['eventResultTitle']!,
          eventResultContent: result['eventResultContent']!,
        );
        await Schedule_CRUD.updateEventResult(updatedEventResult);
      } else {
        // 새로운 결과 추가
        final newEventResult = EventResultModel(
          eventResultId: '${selectedDate.millisecondsSinceEpoch}:${index}',
          eventId: 'eventId',
          categoryId: 'categoryId',
          userId: 'userId',
          eventResultDate: selectedDate,
          eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
          eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
          eventResultTitle: result['eventResultTitle']!,
          eventResultContent: result['eventResultContent']!,
          completeYn: 'N',
        );
        await Schedule_CRUD.createEventResult(newEventResult);
      }
      _loadResults();
    }
  }

  void _copyPlanToActual(int index) async {
    if (_isChecked[index]) {
      final eventModel = scheduleList[index];
      final newEventResult = EventResultModel(
        eventResultId: '${selectedDate.millisecondsSinceEpoch}:${index}',
        eventId: eventModel.eventId,
        categoryId: eventModel.categoryId,
        userId: eventModel.userId,
        eventResultDate: selectedDate,
        eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
        eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
        eventResultTitle: eventModel.eventTitle,
        eventResultContent: eventModel.eventContent ?? '',
        completeYn: 'N',
      );

      await Schedule_CRUD.createEventResult(newEventResult);
      _loadResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double planColumnWidth = screenWidth * 0.3;
    double actualColumnWidth = screenWidth * 0.3;
    double timeColumnWidth = screenWidth * 0.15;
    double adjustColumnWidth = screenWidth * 0.1;
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () => _updateDate(-1),
            ),
            Text(formattedDate),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () => _updateDate(1),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 5,
          showCheckboxColumn: true,
          columns: [
            DataColumn(
              label: Container(
                width: timeColumnWidth,
                child: Text('시간'),
              ),
            ),
            DataColumn(
              label: Container(
                width: planColumnWidth,
                child: Text('일정'),
              ),
            ),
            DataColumn(
              label: Container(
                width: actualColumnWidth,
                child: Text('결과'),
              ),
            ),
          ],
          rows: List.generate(
            timeList.length,
                (index) => DataRow(
              selected: _isChecked[index],
              onSelectChanged: (value) {
                setState(() {
                  _isChecked[index] = value!;
                  if (value) {
                    _copyPlanToActual(index);
                  }
                });
              },
              cells: [
                DataCell(
                  Container(
                    width: timeColumnWidth,
                    child: Text(
                      timeList[index],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    width: planColumnWidth,
                    child: Text(
                      scheduleList[index].eventTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    _addSchedule(index);
                  },
                ),
                DataCell(
                  Container(
                    width: actualColumnWidth,
                    child: Text(
                      resultList[index].eventResultTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    _add_actually_Schedule(index);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}