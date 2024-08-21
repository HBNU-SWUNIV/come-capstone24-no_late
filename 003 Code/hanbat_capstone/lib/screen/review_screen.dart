import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:hanbat_capstone/component/review_list_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';
import 'package:hanbat_capstone/screen/review_title_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanbat_capstone/services/review_service.dart';
import 'package:intl/intl.dart';

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
  late Future<String> aiReviewText;

  @override
  void initState() {
    super.initState();
    reviewData = reviewList();
    aiReviewText = fetchAiReviewText();
  }

  /**
   * 계획 및 결과 요약정보 조회
   */
  Future<String> fetchAiReviewText() async {
    return await _reviewService.summarizeRetrospective(currentDay);
  }

  /**
   * 리뷰 목록 조회
   */
  Future<List<Map<String, dynamic>>> reviewList() async {
    List<Map<String, dynamic>> joinData = [];
    var currentDate = DateFormat('yyyyMMdd').format(currentDay);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

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
          .where('userId', isEqualTo: 'yjkoo') // TODO 하드코딩 수정필요
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
            joinData.add({'type': 'review', 'review': ReviewModel(reviewId: '', userId: 'yjkoo', reviewDate: today, reviewTitle: reviewTitle.titleNm, reviewContent: reviewTitle.hintText)});
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
                        TextButton(onPressed: () {}, child: Text("")),
                        TextButton.icon(
                          onPressed: onPressSettingBtn,
                          label: Text('커스텀'),
                          icon: Icon(Icons.settings),)
                      ],
                    ),
                    FutureBuilder<String>(
                      future: fetchAiReviewText(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Container(
                            color: Colors.grey[200],
                            constraints: BoxConstraints(
                              minHeight: 100,
                            ),
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Text(
                              '오류 : ${snapshot.error}',
                              style: TextStyle(fontSize: 15),
                            ),
                          );
                        } else if (snapshot.hasData) {
                          return Container( // Expanded 대신 Container 사용
                            constraints: BoxConstraints(
                              minHeight: 100,
                            ),
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Text(
                              snapshot.data ?? 'No data available',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        } else {
                          return Container(
                            color: Colors.grey[200],
                            constraints: BoxConstraints(
                              minHeight: 100,
                            ),
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Text(
                              '오류 : 데이터가 없습니다.',
                              style: TextStyle(fontSize: 15),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.85 + bottomInset,
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
                                          userId: 'yjkoo',  // TODO 하드코딩 변경해야함
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
                                          userId: 'yjkoo',  // TODO 하드코딩 변경해야함
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
      reviewData = reviewList();  // 날짜 변경 시 데이터 다시 로드
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
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      // 캘린더만 띄움.
      barrierDismissible: true, // 외부에서 탭할 경우 다이얼로그 닫기
    );

    if (selectedDate != null) {
      setState(() {
        currentDay = selectedDate;
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
