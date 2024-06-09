import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/review_add_screen.dart';

class ReviewListField extends StatelessWidget {
  final String title;
  final String content;

  final String reviewId;
  final String userId;
  final DateTime reviewDate;
  final String reviewContent;
  final callback;

  const ReviewListField({
    required this.title,
    required this.content,

    required this.reviewId,
    required this.userId,
    required this.reviewDate,
    required this.reviewContent,

    this.callback,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.black12),
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: IntrinsicHeight(
          //높이를 내부 위젯들의 최대 높이로 설정
          child: Column(
            children: [
              Container(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10,),
              Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.all(15),
                    child: Text(content,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  )),
              SizedBox(height: 10,),
              Container(
                alignment: Alignment.bottomRight,
                child: IconButton(
                    onPressed: (){
                      showModalBottomSheet(context: context
                          , isDismissible: true
                          , builder: (_) => ReviewAddScreen(
                            reviewTitle: title,
                            reviewId: reviewId.isNotEmpty ? reviewId : null,
                            userId: userId,
                            reviewDate: reviewDate,
                            reviewContent: reviewContent,
                          )
                          , isScrollControlled: true
                      ).then((value) {
                        callback();
                      });
                    }, icon: Icon(Icons.edit)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

