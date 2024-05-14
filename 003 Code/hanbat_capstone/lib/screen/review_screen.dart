import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/component/review_text_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key:key);

  @override
  State createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final GlobalKey<FormState> formkey = GlobalKey();

  String? reviewId;
  String? userId;
  DateTime? reviewDate;
  String? reviewTitle;
  String? reviewContent;

  DateTime currentDay = DateTime.now(); // 선택된 날짜

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Form(
      key: formkey,
      child: Scaffold(
        appBar: AppBar(
          title: TopDatePicker(
            onPressBackBtn: onPressBackBtn,
            onPressDate: onPressDate,
            onPressForwardBtn: onPressForwardBtn,
            currentDay: currentDay,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints){
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(onPressed: (){},child: Text("\u{1F601}")),
                        IconButton(onPressed: (){}, icon: Icon(Icons.settings))
                      ],
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.85 + bottomInset,
                      child: ListView(
                        children: [
                          ReviewTextField(
                            onSaved: (String? val) {
                              reviewId =  '${currentDay.year}${currentDay.month.toString().padLeft(2,'0')}${currentDay.day.toString().padLeft(2,'0')}:1';
                              reviewDate = currentDay;
                              userId = "yjkoo";
                              reviewTitle = "일기";
                              reviewContent = val;
                            },
                            validator: contentValidator,
                            title: "일기",
                            content: "오늘 하루 어땠나요?",
                          ),
                          ReviewTextField(
                            onSaved: (String? val) {
                              reviewId =  '${currentDay.year}${currentDay.month.toString().padLeft(2,'0')}${currentDay.day.toString().padLeft(2,'0')}:2';
                              reviewDate = currentDay;
                              userId = "yjkoo";
                              reviewTitle = "오늘의 쓴소리";
                              reviewContent = val;
                            },
                            validator: contentValidator,
                            title: "오늘의 쓴소리",
                            content: "오늘 나에게 하고싶은 말은?",
                          ),
                          ElevatedButton(onPressed: onSaveBtn, child: Text("저장하기"))
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /**
   * 날짜 이전 버튼 눌렀을때 이벤트
   * - currentDay - 1 인 날짜를 셋팅한다.
   */
  void onPressBackBtn() {
    setState(() {
      currentDay = currentDay.subtract(Duration(days: 1));
    });
  }

  /**
   * 상단 날짜를 눌렀을때 이벤트
   * - 날짜 선택 다이얼로그 띄운다.
   */
  void onPressDate() async {
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: currentDay,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialEntryMode: DatePickerEntryMode.calendarOnly, // 캘린더만 띄움.
        barrierDismissible: true,  // 외부에서 탭할 경우 다이얼로그 닫기
    );

    if(selectedDate != null) {
      setState(() {
        currentDay = selectedDate;
      });
    }
  }

  /**
   * 날짜 이후 버튼 눌렀을 때 이벤트
   * - currentDay + 1 인 날짜를 셋팅한다.
   */
  void onPressForwardBtn() {
    setState(() {
      currentDay = currentDay.add(Duration(days: 1));
    });
  }

  void onSaveBtn() async {
    if (formkey.currentState!.validate()){
      formkey.currentState!.save();

      final review = ReviewModel(
        reviewId: reviewId!,
        userId: userId!,
        reviewDate: reviewDate!,
        reviewTitle: reviewTitle!,
        reviewContent: reviewContent!,
      );
      
      await FirebaseFirestore.instance
        .collection('review',)
        .doc(review.reviewId)
        .set(review.toJson());
    }
  }

  /**
   * 내용 검증 확인 함수
   */
  String? contentValidator(String? val) {
    return null;
  }
}
