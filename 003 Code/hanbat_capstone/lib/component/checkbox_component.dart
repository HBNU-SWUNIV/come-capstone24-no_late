import 'package:flutter/material.dart';

class CheckboxComponent extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final Color checkColor;
  final Color? activeColor;

  CheckboxComponent({
    Key? key,
    required this.isChecked,
    required this.onChanged,
    this.checkColor = Colors.white,
    this.activeColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      onChanged: onChanged,
      activeColor: activeColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}