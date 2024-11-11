import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  void _selectDate(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomScrollDatePicker(
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        onDateChanged(selectedDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.lightBlue[900], // AppBar와 같은 색상
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.white),
              onPressed: onPreviousDay,
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                DateFormat('yyyy-MM-dd').format(selectedDate),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.white),
              onPressed: onNextDay,
            ),
          ],
        ),
      ),
    );
  }
}

class CustomScrollDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  CustomScrollDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  _CustomScrollDatePickerState createState() => _CustomScrollDatePickerState();
}

class _CustomScrollDatePickerState extends State<CustomScrollDatePicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  final Color mainColor = Colors.lightBlue[900]!;
  final Color backgroundColor = Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDayIfNeeded() {
    int daysInMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > daysInMonth) {
      setState(() {
        _selectedDay = daysInMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '날짜 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.white),
                ],
              ),
            ),
            // 날짜 선택 영역
            Container(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 년도 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('년', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedYear - widget.firstDate.year,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedYear = widget.firstDate.year + index;
                                _updateDayIfNeeded();
                              });
                            },
                            children: List<Widget>.generate(
                              widget.lastDate.year - widget.firstDate.year + 1,
                                  (index) => Center(
                                child: Text(
                                  '${widget.firstDate.year + index}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // 월 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('월', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedMonth - 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedMonth = index + 1;
                                _updateDayIfNeeded();
                              });
                            },
                            children: List<Widget>.generate(
                              12,
                                  (index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // 일 선택
                  Expanded(
                    child: Column(
                      children: [
                        Text('일', style: TextStyle(color: Colors.grey[600])),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedDay - 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedDay = index + 1;
                              });
                            },
                            children: List<Widget>.generate(
                              _getDaysInMonth(_selectedYear, _selectedMonth),
                                  (index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 버튼 영역
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        DateTime(_selectedYear, _selectedMonth, _selectedDay),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}