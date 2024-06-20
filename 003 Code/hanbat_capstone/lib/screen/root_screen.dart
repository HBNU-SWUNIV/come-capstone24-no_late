import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'schedule_screen.dart';

import 'add_event_screen.dart';
import 'review_screen.dart';
import 'setting_screen.dart';
import 'calendar_screen.dart';

class RootScreen extends StatefulWidget {
  // const RootScreen({Key? key}) : super(key: key);

  final DateTime? selectedDate;

  const RootScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedIndex = 1; // 스케줄 화면으로 이동
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> renderChildren(DateTime? selectedDate) => <Widget>[
    CalendarScreen(),

    TimeListView(selectedDate: selectedDate),
    AddEventScreen(),

    ReviewScreen(), // 회고관리 화면 연결
    SettingScreen() // 설정관리 화면 연결
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // child: renderChildren.elementAt(_selectedIndex),
        child: renderChildren(widget.selectedDate).elementAt(_selectedIndex),
      ),
      bottomNavigationBar: renderBottomNavigation(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 채팅창 열기
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          );
        },
        child: Icon(Icons.chat),
      ),
    );
  }




  BottomNavigationBar renderBottomNavigation() {
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_day),
            label: '하루일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: '일정추가',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: '회고관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          )
        ]);
  }
}
