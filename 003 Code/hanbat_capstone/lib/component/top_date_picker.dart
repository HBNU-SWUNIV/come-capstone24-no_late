import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TopDatePicker extends StatelessWidget {

  final GestureTapCallback onPressDate;
  final GestureTapCallback onPressBackBtn;
  final GestureTapCallback onPressForwardBtn;
  final DateTime currentDay;

  TopDatePicker({
    required this.onPressDate,
    required this.onPressBackBtn,
    required this.onPressForwardBtn,
    required this.currentDay
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: onPressBackBtn,
        ),
        TextButton(
          onPressed: onPressDate,
          child: Text('${currentDay.year}-${currentDay.month}-${currentDay.day}'
          ,style: TextStyle(color: Colors.white),),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: onPressForwardBtn,
        )
      ],
    );
  }
}