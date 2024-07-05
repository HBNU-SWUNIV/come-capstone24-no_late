import 'package:flutter/material.dart';

class TimeCell extends StatelessWidget {
  final String time;

  TimeCell({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      child: Text(
        time,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}