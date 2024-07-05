import 'package:flutter/material.dart';

class CheckboxComponent extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  CheckboxComponent({required this.isChecked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      onChanged: onChanged,
    );
  }
}