import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/chart_screen.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/statistics_provider.dart';
import 'chat_screen.dart';
import 'schedule_screen.dart';
import 'add_event_screen.dart';
import 'review_screen.dart';
import 'setting_screen.dart';
import 'calendar_screen.dart';
import 'package:hanbat_capstone/services/notification_service.dart';

class RootScreen extends StatefulWidget {
  // const RootScreen({Key? key}) : super(key: key);

  final DateTime? selectedDate;
  final NotificationService notificationService;

  const RootScreen({
    Key? key,
    this.selectedDate,
    required this.notificationService,
  }) : super(key: key);

  @override
  State createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CalendarScreenState> _calendarKey =
  GlobalKey<CalendarScreenState>();
  final GlobalKey<ScheduleScreenState> _scheduleKey = GlobalKey<ScheduleScreenState>();
  late List<Widget> _screens;
  late CategoryProvider _categoryProvider;


  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedIndex = 1; // 스케줄 화면으로 이동
    }
    _categoryProvider = CategoryProvider();
    _categoryProvider.loadCategories();  // 카테고리 초기 로드
    _initializeScreens();
  }


  void _initializeScreens() {
    _screens = [
      CalendarScreen( key: _calendarKey,
        onEventUpdated: _refreshAllScreens,  // 캘린더에서 일정 업데이트 시 호출할 콜백
      ),
      ScheduleScreen( key: _scheduleKey,
        selectedDate: widget.selectedDate ?? DateTime.now(),
        // onEventUpdated: _refreshAllScreens,  // 스케줄러에서 일정 업데이트 시 호출할 콜백
        onEventUpdated: () {
          // 스케줄러에서 이벤트가 업데이트되면 캘린더도 새로고침
          _calendarKey.currentState?.refreshCalendar();
          _categoryProvider.loadCategories();  // 카테고리 새로고침
        },
      ),
      AddEventScreen(
        onEventAdded: () {
          _refreshAllScreens();
          _categoryProvider.loadCategories();  // 카테고리 새로고침
        },
      ),
      ReviewScreen(),
      ChartScreen(),
      SettingScreen(),
    ];
  }
  void _refreshAllScreens() {
    _calendarKey.currentState?.refreshCalendar();
    _scheduleKey.currentState?.refreshSchedule();
  }



  void _onItemTapped(int index) {
    setState(() {
      if(index == 2) {
        _onAddEvent();
      } else {
        // 탭 전환 시 화면 갱신
        if (_selectedIndex != index) {
          _selectedIndex = index;
          _refreshAllScreens();

          // 통계 화면으로 이동할 때 새로고침
          if (index == 4) { // 통계 탭 인덱스
            final chartScreen = _screens[4] as ChartScreen;
            Provider.of<StatisticsProvider>(context, listen: false).forceRefresh();
          }
        }
      }
    });
  }

  List<Widget> renderChildren(DateTime? selectedDate) => <Widget>[
    CalendarScreen(key: _calendarKey),
    ScheduleScreen(selectedDate: selectedDate ?? DateTime.now()),
    AddEventScreen(),
    ReviewScreen(), // 회고관리 화면 연결
    ChartScreen(),
    SettingScreen(), // 설정관리 화면 연결
  ];

  void _onAddEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>AddEventScreen(
          selectedDate: widget.selectedDate,
          onEventAdded: () {
            _refreshAllScreens();
            _categoryProvider.loadCategories();  // 카테고리 새로고침
          },
        ),
      ),
    );
    if (result == true) {
      // 이벤트가 저장되었다면 캘린더 화면 갱신
      _calendarKey.currentState?.refreshCalendar();
      _refreshScheduleScreen();
      _categoryProvider.loadCategories();  // 카테고리 새로고침
      setState(() {
        _selectedIndex = 0; // 캘린더 화면으로 이동
      });
    }
  }

  void _refreshScheduleScreen() {
    setState(() {
      _screens[1] = ScheduleScreen(selectedDate: widget.selectedDate ?? DateTime.now());
    });
  }

  void _updateScreens() {
    _calendarKey.currentState?.refreshCalendar();
    _refreshScheduleScreen();
    setState(() {
      _selectedIndex = 0; // 캘린더 화면으로 이동
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: renderBottomNavigation(),
      floatingActionButton: _selectedIndex == 3 || _selectedIndex == 5
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
                if (result == true) {
                  // 캘린더 업데이트가 필요한 경우
                  _updateScreens();  // 캘린더 이벤트를 다시 불러오는 메서드
                }
              },
              backgroundColor:  Colors.lightBlue[900], // 배경색을 보라색으로 변경
              foregroundColor: Colors.white, // 아이콘 색상을 흰색으로 변경
              child: Icon(Icons.chat),
            )
    );
  }

  BottomNavigationBar renderBottomNavigation() {
    return BottomNavigationBar(
      selectedItemColor: Colors.lightBlue[900],
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: (index) {
        _onItemTapped(index);
      },
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '캘린더',
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_day),
            label: '하루일정',
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: '일정추가',
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: '회고관리',
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
            backgroundColor: Colors.white)
      ],
    );
  }
}
