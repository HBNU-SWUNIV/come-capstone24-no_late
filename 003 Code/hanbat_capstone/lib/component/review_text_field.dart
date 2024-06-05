import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReviewTextField extends StatelessWidget {

  final String title;
  final String content;

  const ReviewTextField({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15,),
            Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            TextFormField(
              initialValue: content,
              textInputAction: TextInputAction.done,
              cursorColor: Colors.grey,
              maxLines: 4,
              maxLength: 200,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[200],
                hintStyle: TextStyle(
                  color: Colors.grey
                )
              ),
            )
          ],
        );
  }
}