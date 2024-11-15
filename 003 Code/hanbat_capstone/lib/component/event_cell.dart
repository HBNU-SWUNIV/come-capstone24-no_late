// import 'package:flutter/material.dart';
//
// class EventCell extends StatelessWidget {
//   final String eventTitle;
//   final VoidCallback onTap;
//
//   EventCell({required this.eventTitle, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 120,
//         child: Text(
//           eventTitle,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     );
//   }
// }

//---------------------------------------------------------------------
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/category_provider.dart';
//
// class EventCell extends StatelessWidget {
//   final String eventTitle;
//   final String categoryId;
//   final VoidCallback onTap;
//
//   EventCell({
//     required this.eventTitle,
//     required this.categoryId,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final categoryProvider = Provider.of<CategoryProvider>(context);
//     final categoryColor = categoryProvider.categoryColors[categoryId];
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
//         child: Text(
//           eventTitle,
//           style: TextStyle(
//             color: categoryColor != null ? Color(int.parse(categoryColor)) : Colors.black,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     );
//   }
// }
//-----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

class EventCell extends StatelessWidget {
  final String eventTitle;
  final String categoryId;
  final VoidCallback onTap;

  EventCell({
    required this.eventTitle,
    required this.categoryId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        Color backgroundColor = Colors.transparent;
        Color textColor = Colors.black;

        try {
          String? colorString = categoryProvider.categoryColors[categoryId];
          if (colorString != null) {
            Color baseColor = Color(int.parse(colorString));
            backgroundColor = baseColor.withOpacity(0.1);
            textColor = baseColor;
          }
        } catch (e) {
          print('Error parsing color for category $categoryId: $e');
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              eventTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}