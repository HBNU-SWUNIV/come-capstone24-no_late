import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'schedule_crud.dart';



class schedule_screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimeListView(),
    );
  }
}

class TimeListView extends StatefulWidget {
  @override
  _TimeListViewState createState() => _TimeListViewState();
}

class _TimeListViewState extends State<TimeListView> {
  DateTime selectedDate = DateTime.now();

  final List<String> timeList = List.generate(24, (index) {
    return '${index.toString().padLeft(2, '0')}:00';
  });

  List<Schedule_CRUD> scheduleList = List.generate(24, (_) => Schedule_CRUD(day: DateTime.now().day, time: '', planedwork: '', unplanedwork: ''));

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final schedules = await Schedule_CRUD.getSchedulesByDate(selectedDate);
    setState(() {
      scheduleList = List.generate(24, (index) {
        final time = timeList[index];
        return schedules.firstWhere(
              (schedule) => schedule.time == time,
          orElse: () => Schedule_CRUD(day: selectedDate.day, time: time, planedwork: '', unplanedwork: ''),
        );
      });
    });
  }

  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
      _loadSchedules();
    });
  }

  // void _copyPlanToActual(int index) {
  //   setState(() {
  //     scheduleList[index]['actual'] = scheduleList[index]['plan']!;
  //   });
  // }

  void _copyPlanToActual(int index) {
    setState(() {
      scheduleList[index].unplanedwork = scheduleList[index].planedwork;
      Schedule_CRUD.updateSchedule(scheduleList[index]);
    });
  }

  void _addSchedule(int index) async {
    final schedule = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String planedwork = '';
        return AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '계획'),
                onChanged: (value) {
                  planedwork = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'planedwork': planedwork});
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (schedule != null && schedule['planedwork']!.isNotEmpty) {
      final newSchedule = Schedule_CRUD(
        day: selectedDate.day,
        time: timeList[index],
        planedwork: schedule['planedwork']!,
        unplanedwork: '',
      );
      await Schedule_CRUD.createSchedule(newSchedule);
      setState(() {
        scheduleList[index] = newSchedule;
      });
    }
  }

  void _add_actually_Schedule(int index) async {
    final schedule = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String unplanedwork = '';
        return AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '실제 활동'),
                onChanged: (value) {
                  unplanedwork = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'unplanedwork': unplanedwork});
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (schedule != null && schedule['unplanedwork']!.isNotEmpty) {
      final newSchedule = scheduleList[index].copyWith(unplanedwork: schedule['unplanedwork']!);
      await Schedule_CRUD.updateSchedule(newSchedule);
      setState(() {
        scheduleList[index] = newSchedule;
      });
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
                    scheduleList[index].planedwork,
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
                    scheduleList[index].unplanedwork,
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