import 'package:flutter/material.dart';

class EventCell extends StatelessWidget {
  final String eventTitle;
  final VoidCallback onTap;

  EventCell({required this.eventTitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        child: Text(
          eventTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}