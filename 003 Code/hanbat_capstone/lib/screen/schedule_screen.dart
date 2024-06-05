import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/Schedule_CRUD.dart';
import 'package:intl/intl.dart';
import 'package:hanbat_capstone/model/event_model.dart';
import 'package:hanbat_capstone/model/event_result_model.dart';
import 'add_event_screen.dart';
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

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    _loadSchedules();
    _loadResults();
  }

  Future<void> _loadSchedules() async {
    // Firestore에서 선택한 날짜의 EventModel 데이터를 가져와 scheduleList를 업데이트하는 로직
    // ...
  }

  Future<void> _loadResults() async {
    final results = await Schedule_CRUD.getEventResultsByDate(selectedDate);
    setState(() {
      resultList = List.generate(24, (index) {
        final time = timeList[index];
        return results.firstWhere(
              (result) => DateFormat('HH:mm').format(result.eventResultSttTime) == time,
          orElse: () => EventResultModel(
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
          ),
        );
      });
    });
  }

  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
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
    final eventResult = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String eventResultTitle = '';
        String eventResultContent = '';
        return AlertDialog(
          title: const Text('일정 결과 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '결과 제목'),
                onChanged: (value) {
                  eventResultTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: '결과 내용'),
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
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (eventResult != null && eventResult['eventResultTitle']!.isNotEmpty) {
      final newEventResult = EventResultModel(
        eventResultId: '${selectedDate.millisecondsSinceEpoch}:${index}',
        eventId: 'eventId',  // 실제 eventId로 변경 필요
        categoryId: 'categoryId',  // 실제 categoryId로 변경 필요
        userId: 'userId',  // 실제 userId로 변경 필요
        eventResultDate: selectedDate,
        eventResultSttTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index),
        eventResultEndTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, index + 1),
        eventResultTitle: eventResult['eventResultTitle']!,
        eventResultContent: eventResult['eventResultContent']!,
        completeYn: 'N',
      );
      await Schedule_CRUD.createEventResult(newEventResult);
      _loadResults();  // 결과 리스트 갱신
    }
  }


  //copyPlanToResult 클래스
  void _copyPlanToActual(int index) async {
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
                width: adjustColumnWidth,
                child: Text(''),
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
                (index) => DataRow(cells: [
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
                  width: adjustColumnWidth,
                  child: IconButton(
                    icon: Icon(Icons.arrow_right_alt),
                    onPressed: () {
                      _copyPlanToActual(index);
                    },
                  ),
                ),
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
            ]),
          ),
        ),
      ),
    );
  }
}