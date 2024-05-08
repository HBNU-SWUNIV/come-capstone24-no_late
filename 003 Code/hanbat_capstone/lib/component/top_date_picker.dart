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
    return SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton.icon(
              label: Text(""),
              icon: Icon(Icons.arrow_back),
              onPressed: onPressBackBtn,
            ),
            TextButton(
              onPressed: onPressDate,
              child: Text('${currentDay.year}.${currentDay.month}.${currentDay.day}'),
            ),
            TextButton.icon(
              label: Text(""),
              icon: Icon(Icons.arrow_forward),
              onPressed: onPressForwardBtn,
            )
          ],
        )
    );
  }
}