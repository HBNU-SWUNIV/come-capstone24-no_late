import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';
import 'package:uuid/uuid.dart';

class ReviewAddScreen extends StatefulWidget {

  final String reviewTitle;
  final String? reviewId;
  final String userId;
  final DateTime reviewDate;
  final String? reviewContent;

  const ReviewAddScreen({
    Key? key,
    required this.reviewTitle,
    this.reviewId,
    required this.userId,
    required this.reviewDate,
    this.reviewContent,
  }) : super(key: key);

  //ReviewAddScreen({this.reviewTitleModel, this.reviewDate, this.userId});

  @override
  State createState() => _ReviewAddScreenState();
}

class _ReviewAddScreenState extends State<ReviewAddScreen> {
  final GlobalKey<FormState> formkey = GlobalKey();

  late String reviewTitle;
  late String? reviewId;
  late String userId;
  late DateTime reviewDate;
  late String? reviewContent;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    reviewTitle = widget.reviewTitle;
    reviewId = widget.reviewId;
    userId = widget.userId;
    reviewDate = widget.reviewDate;
    reviewContent = widget.reviewContent;
    _contentController = TextEditingController(text: reviewContent);
  }

  @override
  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height / 2 + bottomInset,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15,),
              Text(
                reviewTitle,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black
                ),
              ),
              const SizedBox(height: 15,),
              Expanded(child: TextFormField(
                controller: _contentController,
                cursorColor: Colors.grey,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[200]
                ),
              )),
              const SizedBox(height: 15,),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onSavePressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[900]!,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                    )
                  ), child: Text('저장',style: TextStyle(fontSize: 18,color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15,),
            ],
          ),
        )
      ),
    );
  }

  void onSavePressed(BuildContext context) async {
    reviewContent = _contentController.text;

    final reviewModel = ReviewModel(
      reviewId: reviewId ?? Uuid().v4(),
      userId: userId,
      reviewDate: reviewDate,
      reviewTitle: reviewTitle,
      reviewContent: reviewContent!,
    );

    final firestore = FirebaseFirestore.instance;

    if (reviewId == null) {
      // 새로운 리뷰 생성
      reviewId = reviewModel.reviewId;
      await firestore.collection('review').doc(reviewId).set(reviewModel.toJson());
    } else {
      // 기존 리뷰 업데이트
      await firestore.collection('review').doc(reviewId).update(reviewModel.toJson());
    }
    
    showDialog<String>(
        context: context, 
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
            ),
            content: const Text("저장되었습니다."),
          );
        });

    await Future.delayed(Duration(milliseconds: 500));
    Navigator.of(context).pop();  // alertDialog 닫기
    Navigator.of(context).pop();  // 부모창으로 이동
  }
}