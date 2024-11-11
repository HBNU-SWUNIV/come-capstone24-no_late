import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:hanbat_capstone/component/review_list_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:hanbat_capstone/const/colors.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';
import 'package:hanbat_capstone/screen/review_title_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanbat_capstone/services/review_service.dart';
import 'package:intl/intl.dart';

import '../component/date_selector.dart';

/**
 * 회고관리 화면
 */
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

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

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ReviewService _reviewService = ReviewService();

  late Future<List<Map<String, dynamic>>> reviewData;
  String? aiReviewText;
  String? aiErrorMessage;

  bool isDate = true;
  bool isWeek = false;
  bool isMonth = false;
  late List<bool> isSelected; // 토글버튼 선택

  @override
  void initState() {
    isSelected = [isDate, isWeek, isMonth];
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    fetchAiReviewText();
    reviewData = reviewList();
  }

  void toggleSelect(value) {
    isDate = value == 0 ? true : false;
    isWeek = value == 1 ? true : false;
    isMonth = value == 2 ? true : false;

    setState(() {
      isSelected = [isDate, isWeek, isMonth];
      aiReviewText = null;
      fetchAiReviewText();
    });
  }

  /**
   * 계획 및 결과 요약정보 조회
   */
  Future<void> fetchAiReviewText() async {
    try {
      var result = null;

      if(isDate){
        result = await _reviewService.summarizeRetrospective(currentDay, userId!);
      }else if(isWeek){
        result = await _reviewService.summarizeRetrospectiveWeek(currentDay, userId!);
      }else{
        result = await _reviewService.summarizeRetrospectiveMonth(currentDay, userId!);
      }

      if(mounted) {
        setState(() {
          aiReviewText = result;
        });
      }
    } catch(e) {
      if(mounted) {
        setState(() {
          aiErrorMessage = '오류가 발생했습니다. \n오류내용 : $e';
        });
      }
    }
  }

  /**
   * 리뷰 목록 조회
   */
  Future<List<Map<String, dynamic>>> reviewList() async {
    List<Map<String, dynamic>> joinData = [];
    var currentDate = DateFormat('yyyyMMdd').format(currentDay);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if(userId == null){
      return joinData;  // userId가 없는경우 빈 리스트 반환
    }

    try {
      // 리뷰 타이틀 목록
      QuerySnapshot reviewTitleSnapshot = await firestore
          .collection('reviewTitle')
          .get();

      List<ReviewTitleModel> reviewTitles = reviewTitleSnapshot.docs
          .map((doc) => ReviewTitleModel.fromDocument(doc))
          .toList();

      // 선택된 날짜의 리뷰 목록
      QuerySnapshot reviewSnapshot = await firestore
          .collection('review')
          .where('userId', isEqualTo: userId)
          .where('reviewDate', isEqualTo: currentDate)
          .get();

      List<ReviewModel> reviews = reviewSnapshot.docs
          .map((doc) => ReviewModel.fromDocument(doc))
          .toList();

      // 1. 리뷰 목록이 없는 경우 ==> 리뷰 타이틀 목록을 보여준다.
      if (reviews.isEmpty) {
        joinData = reviewTitles.map((title) {
          return {
            'type': 'title',
            'data': title
          };
        }).toList();

        // 리뷰타이틀 사용여부(useYn) 가 N인 경우, 해당 아이템을 삭제한다.
        List<Map<String, dynamic>> itemsToRemove = [];  // 삭제할 데이터
        for(var item in joinData){
          ReviewTitleModel dataItem = item['data'];
          if(dataItem.useYn.isEmpty || dataItem.useYn == 'N'){
            itemsToRemove.add(item);
          }
        }
        joinData.removeWhere((item) => itemsToRemove.contains(item));

      }
      // 2. 리뷰 목록이 있는 경우,
      else {
        for (var reviewTitle in reviewTitles) {
          var matchingYn = false;

          // 리뷰 타이틀과 매칭되는 데이터가 있는 경우 항목 추가
          for(var review in reviews) {
            if(reviewTitle.titleNm == review.reviewTitle){
              matchingYn = true;
              joinData.add({'type': 'review', 'review': review});
            }

            if(matchingYn) break;
          }

          // 매칭되지 않는 경우 (= 리뷰가 저장되지 않은 경우) && 리뷰타이틀 사용여부가 Y인 경우 데이터 추가
          if(!matchingYn && reviewTitle.useYn == "Y"){
            joinData.add({'type': 'review', 'review': ReviewModel(reviewId: '', userId: userId!, reviewDate: today, reviewTitle: reviewTitle.titleNm, reviewContent: reviewTitle.hintText)});
          }
        }
      }
    } catch (e) {
      print('Error fetching review data: $e');
    }

    return joinData;
  }

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
        body: SafeArea(child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(width: 5,),
                            ToggleButtons(
                              disabledColor: Colors.white,
                              renderBorder: false,
                              borderRadius: BorderRadius.circular(10),
                              borderWidth: 0,
                              borderColor: Colors.white,
                              selectedBorderColor: Colors.white,
                              fillColor: Colors.white,
                              color: Colors.grey,
                              selectedColor: Colors.lightBlue[900],
                              children: [
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Text('일별 요약')
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Text('주별 요약')
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Text('월별 요약')
                              ),
                            ],
                              isSelected: isSelected,
                            onPressed: toggleSelect,)
                          ],
                        ),
                        IconButton(onPressed: onPressSettingBtn, icon: Icon(Icons.settings, color:Colors.lightBlue[900]))
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.all(5),
                      // constraints: BoxConstraints(
                      //   maxHeight: 150
                      // ),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(width: 1, color: COLOR_GREY_200!)),
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.all(15),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          aiReviewText ?? aiErrorMessage ?? 'chatGPT가 열심히 분석하고 있어요 !\n잠시만 기다려주세요!',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.7 + bottomInset,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: reviewData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text('회고 정보가 없습니다.'),
                            );
                          }

                          List<Map<String, dynamic>> joinData = snapshot.data!;

                          return ListView.builder(
                              itemCount: joinData.length,
                              itemBuilder: (context, index) {
                                var item = joinData[index];
                                if (item['type'] == 'title') {
                                  ReviewTitleModel titleModel = item['data'];
                                  return Column(
                                    children: [
                                      ReviewListField(
                                          title: titleModel.titleNm,
                                          content: titleModel.hintText,
                                          reviewId: '',
                                          userId: userId!,
                                          reviewContent: '',
                                          reviewDate: currentDay,
                                          callback: callback,
                                      ),
                                    ],
                                  );
                                } else {
                                  ReviewModel reviewModel = item['review'];

                                  return Column(
                                    children: [
                                      ReviewListField(
                                          title: reviewModel.reviewTitle,
                                          content: reviewModel.reviewContent,
                                          reviewId: reviewModel.reviewId,
                                          userId: userId!,
                                          reviewContent: reviewModel.reviewContent,
                                          reviewDate: reviewModel.reviewDate,
                                          callback: callback,
                                      )
                                    ],
                                  );
                                }
                              });
                        },
                      ),
                    ),
                  ],
                ),
              );
            })),
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
      //aiReviewText = null;
      toggleSelect(0);
      //fetchAiReviewText();
      reviewData = reviewList();  // 날짜 변경 시 데이터 다시 로드
    });
  }

  /**
   * 상단 날짜를 눌렀을때 이벤트
   * - 날짜 선택 다이얼로그 띄운다.
   */
  void onPressDate() async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomScrollDatePicker(
          initialDate: currentDay,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        currentDay = selectedDate;
        //aiReviewText = null;
        //fetchAiReviewText();
        toggleSelect(0);
        reviewData = reviewList();  // 날짜 변경 시 데이터 다시 로드
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
      //aiReviewText = null;
      //fetchAiReviewText();
      toggleSelect(0);
      reviewData = reviewList();  // 날짜 변경 시 데이터 다시 로드
    });
  }

  /**
   * 셋팅 버튼 눌렀을 때 이벤트
   * - 일기 항목 저장하는 화면으로 이동
   */
  void onPressSettingBtn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewTitleScreen(),
      ),
    ).then((value) {
      setState(() {
        reviewData = reviewList();
      });
    });
  }

  void callback() {
    setState(() {
      reviewData = reviewList();
    });
  }
}
