import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hanbat_capstone/component/review_text_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:hanbat_capstone/model/review_model.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';
import 'package:hanbat_capstone/screen/review_add_screen.dart';
import 'package:hanbat_capstone/screen/review_title_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    DateTime
        .now()
        .year,
    DateTime
        .now()
        .month,
    DateTime
        .now()
        .day,
  );

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> reviewData;

  @override
  void initState() {
    reviewData = reviewList();
  }

  /**
   * 리뷰 목록 조회
   */
  Future<List<Map<String, dynamic>>> reviewList() async {
    List<Map<String, dynamic>> joinData = [];
    var currentDate = DateFormat('yyyyMMdd').format(currentDay);

    // 리뷰 타이틀 목록
    QuerySnapshot reviewTitleSnapshot = await firestore
        .collection('reviewTitle')
    //.where('userId', isEqualTo: 'yjkoo') // TODO 추가필요
        .where('useYn', isEqualTo: 'Y')
        .get();

    List<ReviewTitleModel> reviewTitles = reviewTitleSnapshot.docs
        .map((doc) => ReviewTitleModel.fromDocument(doc))
        .toList();

    // 선택된 날짜의 리뷰 목록
    QuerySnapshot reviewSnapshot = await firestore
        .collection('review')
    //.where('userId', isEqualTo: 'yjkoo') // TODO 추가필요
        .where('reviewDate', isEqualTo: DateTime.parse(currentDate))
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
          //title.toJson();
        };
      }).toList();
    }
    // 2. 리뷰 목록이 있는 경우,
    else {
      DateTime today = DateTime.now();

      for (var review in reviews) {
        // 2-1. 선택된 날짜가 현재 날짜 같거나 이후인 경우 => 저장하지 않은 리뷰타이틀 목록도 같이 보여준다.
        if (review.reviewDate.isAfter(today) ||
            review.reviewDate.isAtSameMomentAs(today)) {
          var matchingTitle = reviewTitles.firstWhere(
                  (title) => title.titleNm == review.reviewTitle,
              orElse: () =>
                  ReviewTitleModel(
                      userId: 'yjkoo',
                      seq: 0,
                      titleId: '',
                      titleNm: '',
                      hintText: '',
                      useYn: 'N'));

          joinData.add(
              {'type': 'review', 'review': review, 'title': matchingTitle});
        }

        joinData.add({
          'type': 'review',
          'review': review,
        });
      }
    }
    return joinData;
  }

  /**
   * 리뷰 정보 수정
   */
  Future<void> updateReviewContent(String reviewId, String newContent) async {
    await firestore
        .collection('review')
        .doc(reviewId)
        .update({'reviewContent': newContent});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery
        .of(context)
        .viewInsets
        .bottom;
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
                    SizedBox(
                      height: constraints.maxHeight * 0.85 + bottomInset,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: reviewList(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                                      _ListField(
                                          title: titleModel.titleNm,
                                          content: titleModel.hintText),
                                    ],
                                  );
                                } else {
                                  ReviewModel reviewModel = item['reveiw'];
                                  ReviewTitleModel reviewTitleModel = item['title'];

                                  return Column(
                                    children: [
                                      _ListField(
                                          title: reviewModel.reviewTitle,
                                          content: reviewModel.reviewContent)
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

  /**
   * Edit 버튼 눌렀을 때 이벤트
   * - review 작성 화면으로 이동
   */
  void onPressEditBtn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewAddScreen(),
      ),
    ).then((value) {
      setState(() {
        reviewData = reviewList();
      });
    });
  }

  /**
   * 내용 검증 확인 함수
   */
  String? contentValidator(String? val) {
    return null;
  }
}

/**
 * List Item 컴포넌트
 */
class _ListField extends StatelessWidget {
  final String title;
  final String content;

  const _ListField({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  get onPressEditBtn => null;

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
                    onPressed: onPressEditBtn, icon: Icon(Icons.edit)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
