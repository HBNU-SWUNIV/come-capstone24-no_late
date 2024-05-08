import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReviewTextField extends StatelessWidget {

  final String title;
  final String content;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;

  const ReviewTextField({
    required this.title,
    required this.content,
    required this.onSaved,
    required this.validator,
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
              onSaved: onSaved, // 폼 저장했을 때 실행할 함수
              validator: validator, // 폼 검증했을 때 실행할 함수
              textInputAction: TextInputAction.done,
              cursorColor: Colors.grey,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[200],
                hintText: content,
                hintStyle: TextStyle(
                  color: Colors.grey
                )
              ),
            )
          ],
        );
  }
}