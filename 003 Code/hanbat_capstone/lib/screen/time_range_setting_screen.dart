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
    // Provider를 통해 설정 저장
    await context.read<ScheduleSettingsProvider>().saveSettings(_startTime, _endTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('설정이 저장되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스케줄 시간 설정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시작 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _startTime,
              items: List.generate(25, (index) => DropdownMenuItem(
                value: index,
                child: Text(index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00'),
              )),
              onChanged: (value) {
                setState(() {
                  _startTime = value!;
                  if (_startTime > _endTime) {
                    _endTime = _startTime;
                  }
                });
              },
            ),
            SizedBox(height: 20),
            Text('종료 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _endTime,
              items: List.generate(25, (index) => DropdownMenuItem(
                value: index,
                child: Text(index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00'),
              )),
              onChanged: (value) {
                setState(() {
                  _endTime = value!;
                  if (_endTime < _startTime) {
                    _startTime = _endTime;
                  }
                });
              },
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text('설정 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class TimeRangeSettingScreen extends StatefulWidget {
//   @override
//   _TimeRangeSettingScreenState createState() => _TimeRangeSettingScreenState();
// }
//
// class _TimeRangeSettingScreenState extends State<TimeRangeSettingScreen> {
//   int _startTime = 0;
//   int _endTime = 24;
//   final Color mainColor = Colors.lightBlue[900]!;
//   final Color backgroundColor = Colors.grey[100]!;
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
//     await context.read<ScheduleSettingsProvider>().saveSettings(_startTime, _endTime);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('설정이 저장되었습니다.'),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,  // 배경색을 흰색으로 변경
//       appBar: AppBar(
//         title: Text('스케줄 시간 설정'),
//         centerTitle: true,
//         backgroundColor: mainColor,
//         elevation: 0,
//       ),
//       body:Container(
//         decoration: BoxDecoration(
//           color: Colors.white,  // 컨텐츠 영역 배경색
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     SizedBox(height: 16),  // 상단 여백 추가
//                     // 시작 시간 설정
//                     _buildTimeSection(
//                       title: '시작 시간',
//                       icon: Icons.access_time,
//                       value: _startTime,
//                       onChanged: (value) {
//                         setState(() {
//                           _startTime = value;
//                           if (_startTime > _endTime) {
//                             _endTime = _startTime;
//                           }
//                         });
//                       },
//                     ),
//
//                     SizedBox(height: 20),
//
//                     // 종료 시간 설정
//                     _buildTimeSection(
//                       title: '종료 시간',
//                       icon: Icons.access_time_filled,
//                       value: _endTime,
//                       onChanged: (value) {
//                         setState(() {
//                           _endTime = value;
//                           if (_endTime < _startTime) {
//                             _startTime = _endTime;
//                           }
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // 저장 버튼
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: ElevatedButton(
//                 onPressed: _saveSettings,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: mainColor,
//                   minimumSize: Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   elevation: 2,
//                 ),
//                 child: Text(
//                   '설정 저장',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimeSection({
//     required String title,
//     required IconData icon,
//     required int value,
//     required ValueChanged<int> onChanged,
//   }) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: mainColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: mainColor),
//                 ),
//                 SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Container(
//               height: 150,
//               decoration: BoxDecoration(
//                 color: backgroundColor,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: CupertinoPicker(
//                 scrollController: FixedExtentScrollController(
//                   initialItem: value,
//                 ),
//                 itemExtent: 40,
//                 onSelectedItemChanged: onChanged,
//                 children: List.generate(
//                   25,
//                       (index) => Center(
//                     child: Text(
//                       index == 24 ? '24:00' : '${index.toString().padLeft(2, '0')}:00',
//                       style: TextStyle(
//                         fontSize: 20,
//                         color: mainColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }