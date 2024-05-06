import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// class schedule_screen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Time List',
//       home: Scaffold(
//         body: TimeListView(),
//       ),
//     );
//   }
// }

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

  final List<Map<String, String>> scheduleList =
  List.generate(24, (_) => {'plan': '', 'actual': ''});

  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
    });
  }

  void _copyPlanToActual(int index) {
    setState(() {
      scheduleList[index]['actual'] = scheduleList[index]['plan']!;
    });
  }

  void _addSchedule(int index) async {
    final schedule = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String plan = '';
        return AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '계획'),
                onChanged: (value) {
                  plan = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'plan': plan});
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    // null 확인 및 plan과 actual 중 하나라도 값이 있는지 확인할 때 !.isNotEmpty 사용
    if (schedule != null && (schedule['plan']!.isNotEmpty)) {
      setState(() {
        // scheduleList[index]의 각 키-값 쌍을 개별적으로 업데이트
        scheduleList[index]['plan'] = schedule['plan'] ?? '';
      });
    }
  }

  void _add_actually_Schedule(int index) async {
    final schedule = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String actual = '';
        return AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '실제 활동'),
                onChanged: (value) {
                  actual = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'actual': actual});
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    // null 확인 및 plan과 actual 중 하나라도 값이 있는지 확인할 때 !.isNotEmpty 사용
    if (schedule != null && (schedule['actual']!.isNotEmpty)) {
      setState(() {
        // scheduleList[index]의 각 키-값 쌍을 개별적으로 업데이트

        scheduleList[index]['actual'] = schedule['actual'] ?? '';
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
                    scheduleList[index]['plan']!,
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
                    scheduleList[index]['actual']!,
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
