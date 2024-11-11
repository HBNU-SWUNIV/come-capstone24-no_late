// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../providers/schedulesettings_provider.dart';
//
// class TimeRangeSettingScreen extends StatefulWidget {
//   @override
//   _TimeRangeSettingScreenState createState() => _TimeRangeSettingScreenState();
// }
//
// class _TimeRangeSettingScreenState extends State<TimeRangeSettingScreen> {
//   int _startTime = 0;
//   int _endTime = 24;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }
//
//   _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _startTime = prefs.getInt('startTime') ?? 0;
//       _endTime = prefs.getInt('endTime') ?? 24;
//     });
//   }
//
//   _saveSettings() async {
//     // Provider를 통해 설정 저장
//     await context.read<ScheduleSettingsProvider>().saveSettings(_startTime, _endTime);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('설정이 저장되었습니다.')),
//     );
//
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('스케줄 시간 설정'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('시작 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             DropdownButton<int>(
//               value: _startTime,
//               items: List.generate(25, (index) => DropdownMenuItem(
//                 value: index,
//                 child: Text(index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00'),
//               )),
//               onChanged: (value) {
//                 setState(() {
//                   _startTime = value!;
//                   if (_startTime > _endTime) {
//                     _endTime = _startTime;
//                   }
//                 });
//               },
//             ),
//             SizedBox(height: 20),
//             Text('종료 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             DropdownButton<int>(
//               value: _endTime,
//               items: List.generate(25, (index) => DropdownMenuItem(
//                 value: index,
//                 child: Text(index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00'),
//               )),
//               onChanged: (value) {
//                 setState(() {
//                   _endTime = value!;
//                   if (_endTime < _startTime) {
//                     _startTime = _endTime;
//                   }
//                 });
//               },
//             ),
//             SizedBox(height: 40),
//             Center(
//               child: ElevatedButton(
//                 onPressed: _saveSettings,
//                 child: Text('설정 저장'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/schedulesettings_provider.dart';

class TimeRangeSettingScreen extends StatefulWidget {
  @override
  _TimeRangeSettingScreenState createState() => _TimeRangeSettingScreenState();
}

class _TimeRangeSettingScreenState extends State<TimeRangeSettingScreen> {
  int _startTime = 0;
  int _endTime = 24;
  final Color mainColor = Colors.lightBlue[900]!;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startTime = prefs.getInt('startTime') ?? 0;
      _endTime = prefs.getInt('endTime') ?? 24;
    });
  }

  _saveSettings() async {
    await context.read<ScheduleSettingsProvider>().saveSettings(_startTime, _endTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('설정이 저장되었습니다'),
        backgroundColor: mainColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.pop(context);
  }

  void _showTimePicker(BuildContext context, bool isStartTime) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text('취소'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isStartTime ? '시작 시간' : '종료 시간',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      child: Text('확인'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: isStartTime ? _startTime : _endTime,
                  ),
                  onSelectedItemChanged: (int value) {
                    setState(() {
                      if (isStartTime) {
                        _startTime = value;
                        if (_startTime > _endTime) {
                          _endTime = _startTime;
                        }
                      } else {
                        _endTime = value;
                        if (_endTime < _startTime) {
                          _startTime = _endTime;
                        }
                      }
                    });
                  },
                  children: List<Widget>.generate(25, (int index) {
                    return Center(
                      child: Text(
                        index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('스케줄 시간 설정'),
        backgroundColor: mainColor,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSection('시작 시간', _startTime, true),
            SizedBox(height: 30),
            _buildTimeSection('종료 시간', _endTime, false),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      '설정 저장',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(String title, int value, bool isStartTime) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mainColor,
            ),
          ),
          SizedBox(height: 10),
          InkWell(
            onTap: () => _showTimePicker(context, isStartTime),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: mainColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value == 24 ? '24:00' : '${value.toString().padLeft(2, '0')}:00',
                    style: TextStyle(fontSize: 16),
                  ),
                  Icon(Icons.access_time, color: mainColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}