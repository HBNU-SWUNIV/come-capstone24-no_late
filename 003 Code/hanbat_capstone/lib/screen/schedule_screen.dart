import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Schedule_CRUD.dart';



//schedule_screen 위젯:
// StatelessWidget을 상속받아 구현
// build 메서드에서는 Scaffold 위젯을 반환하고, body에 TimeListView 위젯을 할당
class schedule_screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TimeListView(),
    );
  }
}


//TimeListView 위젯:
// StatefulWidget을 상속받아 구현
// createState 메서드에서 _TimeListViewState를 반환
class TimeListView extends StatefulWidget {
  @override
  _TimeListViewState createState() => _TimeListViewState();
}


//TimeListViewState 클래스:
// TimeListView 위젯의 상태를 관리
// selectedDate, timeList, scheduleList 변수를 적절히 초기화
// initState 메서드에서 _loadSchedules 메서드를 호출하여 초기 데이터를 로드
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


  //_loadSchedules 메서드:
  // 비동기 함수로 구현됨, Schedule_CRUD.getSchedulesByDate 메서드를 사용하여 선택된 날짜의 일정을 가져옴
  // 가져온 일정을 기반으로 scheduleList를 업데이트
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


  //_updateDate 메서드:
  // 선택된 날짜를 변경하고 _loadSchedules 메서드를 호출하여 해당 날짜의 일정을 로드
  void _updateDate(int daysOffset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: daysOffset));
      _loadSchedules();
    });
  }

  // 일단 남겨둔 코드
  // void _copyPlanToActual(int index) {
  //   setState(() {
  //     scheduleList[index]['actual'] = scheduleList[index]['plan']!;
  //   });
  // }

  //_copyPlanToActual 메서드:
  //계획을 실제 활동으로 복사하고, Schedule_CRUD.updateSchedule 메서드를 사용하여 일정을 업데이트
  void _copyPlanToActual(int index) {
    setState(() {
      scheduleList[index].unplanedwork = scheduleList[index].planedwork;
      Schedule_CRUD.updateSchedule(scheduleList[index]);
    });
  }


  //_addSchedule 메서드:
  // 다이얼로그를 통해 새로운 일정을 추가할 수 있음
  // 입력된 값을 기반으로 Schedule_CRUD 객체를 생성하고, Schedule_CRUD.createSchedule 메서드를 사용하여 일정을 생성
  // 생성된 일정을 scheduleList에 추가
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


  //_add_actually_Schedule 메서드:
  // 다이얼로그를 통해 실제 활동을 추가할 수 있음
  // 입력된 값을 기반으로 기존 일정을 업데이트하고, Schedule_CRUD.updateSchedule 메서드를 사용하여 일정을 업데이트
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


  //build 메서드:
  // 화면 크기에 따라 동적으로 컬럼 너비를 계산
  // AppBar에는 선택된 날짜와 이전/다음 날짜로 이동할 수 있는 아이콘 버튼 존재
  // body에는 SingleChildScrollView 내부에 DataTable 위젯 존재
  // DataTable은 시간, 일정, 조정, 결과에 대한 컬럼을 가지고 있음
  // 각 행은 해당 시간대의 일정을 나타내며, 일정과 결과를 탭하여 수정할 수 있음
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