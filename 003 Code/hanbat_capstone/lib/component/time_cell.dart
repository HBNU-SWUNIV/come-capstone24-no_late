import 'package:flutter/material.dart';

class TimeCell extends StatelessWidget {
  final String time;

  TimeCell({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 50,
      child: Center(
        child: Text(
          '${time}시',
          textAlign: TextAlign.center,

        ),
      ),
    );
  }
}