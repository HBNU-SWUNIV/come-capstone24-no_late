import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/schedule_screen.dart';
import 'review_screen.dart';
import 'setting_screen.dart';
import 'calendar_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  State createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: renderChildren.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: renderBottomNavigation(),
    );
  }

  List<Widget> renderChildren = <Widget>[
    CalendarPage(),

    schedule_screen(),
    Container(          // TODO. 일정등록 화면 연결하기
      child: Center(
        child: Text(
            '일정추가'
        ),
      ),
    ),
    ReviewScreen(), // 회고관리 화면 연결
    SettingScreen() // 설정관리 화면 연결
  ];

  BottomNavigationBar renderBottomNavigation(){
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_month
              ),
              label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.calendar_view_day
            ),
            label: '하루일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.add_circle
            ),
            label: '일정추가',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.fact_check
            ),
            label: '회고관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.settings
            ),
            label: '설정',
          )
        ]
    );
  }
}
