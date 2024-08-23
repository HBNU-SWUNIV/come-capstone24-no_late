import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeRangeSettingScreen extends StatefulWidget {
  @override
  _TimeRangeSettingScreenState createState() => _TimeRangeSettingScreenState();
}

class _TimeRangeSettingScreenState extends State<TimeRangeSettingScreen> {
  int _startTime = 0;
  int _endTime = 23;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startTime = prefs.getInt('startTime') ?? 0;
      _endTime = prefs.getInt('endTime') ?? 23;
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startTime', _startTime);
    await prefs.setInt('endTime', _endTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('설정이 저장되었습니다.')),
    );
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
              items: List.generate(24, (index) => DropdownMenuItem(
                value: index,
                child: Text('${index.toString().padLeft(2, '0')}:00'),
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
              items: List.generate(24, (index) => DropdownMenuItem(
                value: index,
                child: Text('${index.toString().padLeft(2, '0')}:00'),
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
                onPressed: () {
                  _saveSettings();
                  Navigator.pop(context);
                },
                child: Text('설정 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}