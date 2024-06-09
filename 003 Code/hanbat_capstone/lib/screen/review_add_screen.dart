import 'package:flutter/cupertino.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';

class ReviewAddScreen extends StatefulWidget {

  const ReviewAddScreen({Key? key}) : super(key: key);

  //ReviewAddScreen({this.reviewTitleModel, this.reviewDate, this.userId});

  @override
  State createState() => _ReviewAddScreenState();
}

class _ReviewAddScreenState extends State<ReviewAddScreen> {

  late final ReviewTitleModel? reviewTitleModel;
  late final DateTime? reviewDate;
  late final String? userId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 10,);
  }
}