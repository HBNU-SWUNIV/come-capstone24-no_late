import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/component/review_text_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';
import 'package:hanbat_capstone/screen/review_title_screen.dart';
import 'package:uuid/uuid.dart';
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

  // 선택된 날짜 관리 변수
  DateTime currentDay = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

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
                        TextButton(onPressed: (){},child: Text("")),
                        IconButton(onPressed: onPressSettingBtn, icon: Icon(Icons.settings))
                      ],
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.85 + bottomInset,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('review')
                            .where('userId', isEqualTo: 'yjkoo')
                            .where('reviewDate', isEqualTo: '${currentDay.year}${currentDay.month}${currentDay.day}')
                            .snapshots(),

                        builder: (context, snapshot) {
                          if(snapshot.hasError){
                            return Center(child: Text('회고 정보를 가져오지 못했습니다.'),);
                          }

                          if(snapshot.connectionState == ConnectionState.waiting){
                            return Center(child: CircularProgressIndicator(),);
                          }

                          // review 데이터가 있는경우
                          if(snapshot.data!.docs.isNotEmpty){
                            final reviews = snapshot.data!.docs.map(
                                    (QueryDocumentSnapshot e) => ReviewModel.fromJson(
                                    json: (e.data() as Map<String, dynamic>)
                                )).toList();

                            return ListView.builder(
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  return ReviewTextField(
                                    title: review.reviewTitle,
                                    content: review.reviewContent,
                                  );
                                }
                            );
                          }else{

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('reviewTitle')
                                  .where('userId', isEqualTo: 'yjkoo')
                                  .where('useYn', isEqualTo: 'Y')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if(snapshot.hasError){
                                  return Center(child: Text('회고 정보를 가져오지 못했습니다.'),);
                                }

                                if(snapshot.connectionState == ConnectionState.waiting){
                                  return Center(child: CircularProgressIndicator(),);
                                }

                                if(snapshot.hasData){
                                  final reviewTitles = snapshot.data!.docs.map(
                                          (QueryDocumentSnapshot e) => ReviewTitleModel.fromJson(
                                          json: (e.data() as Map<String, dynamic>)
                                      )).toList();
                                  return ListView.builder(
                                      itemCount: reviewTitles.length,
                                      itemBuilder: (context, index) {
                                        final reviewTitle = reviewTitles[index];
                                        return ReviewTextField(
                                          title: reviewTitle.titleNm,
                                          content: "",
                                        );
                                      }
                                  );
                                }else{
                                  return Center(child: Text('회고 정보를 가져오지 못했습니다.'),);
                                }
                              },
                            );
                          }
                        },
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

  /**
   * 셋팅 버튼 눌렀을 때 이벤트
   * - 일기 항목 저장하는 화면으로 이동
   */
  void onPressSettingBtn(){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewTitleScreen(

        ),
      ),
    );
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


  Future createReview(Map<String, dynamic> json) async {
    DocumentReference<Map<String, dynamic>> documentReference =
    FirebaseFirestore.instance.collection("review").doc();
    final DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await documentReference.get();

    if (!documentSnapshot.exists) {
      await documentReference.set(json);
    }
  }

  /**
   * 내용 검증 확인 함수
   */
  String? contentValidator(String? val) {
    return null;
  }
}
