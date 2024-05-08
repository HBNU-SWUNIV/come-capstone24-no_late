import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/component/review_text_field.dart';
import 'package:hanbat_capstone/component/top_date_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key:key);

  @override
  State createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final GlobalKey<FormState> formkey = GlobalKey();

  String? content;  // 내용 저장 변수
  DateTime currentDay = DateTime.now(); // 선택된 날짜

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Form(
      key: formkey,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints){
            return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      //height: constraints.maxHeight * 0.15,
                      child: Column(
                        children: [
                          TopDatePicker(onPressDate: onPressDate, onPressBackBtn: onPressBackBtn, onPressForwardBtn: onPressForwardBtn, currentDay: currentDay),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                  onPressed: (){},
                                  child: Text("\u{1F601}")
                              ),
                              TextButton.icon(
                                  onPressed: onDBTest,
                                  icon: Icon(Icons.settings),
                                  label: Text('')
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.85 + bottomInset,
                      child: ListView(
                        children: [
                          ReviewTextField(
                              onSaved: (String? val){
                                content = val;
                              },
                              validator: contentValidator,
                              title: "일기", content: "오늘 하루 어땠나요?"),
                          ReviewTextField(
                              onSaved: (String? val){
                                content = val;
                              },
                              validator: contentValidator,
                              title: "오늘 가장 좋았던 일", content: "오늘은 뭐가 제일 좋았나요?"),
                          ReviewTextField(
                              onSaved: (String? val){
                                content = val;
                              },
                              validator: contentValidator,
                              title: "나에게 한마디", content: "나에게 하고 싶은 말을 적어봐요!"),
                          ReviewTextField(
                              onSaved: (String? val){
                                content = val;
                              },
                              validator: contentValidator,
                              title: "오늘의 쓴소리", content: "오늘 하루 반성하고 싶었던 말을 적어봐요!"),
                        ],
                      ),
                    ),
                  ],
                )
            );
          },
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
   * TODO. 테스트용으로 변경필요
   */
  void onDBTest() {
    // null값이 아니기 때문에 formkey.currentState!
    if(formkey.currentState!.validate()){ // 폼 검증
      formkey.currentState!.save(); // 폼 저장
      print(content);
    }
  }

  /**
   * 내용 검증 확인 함수
   */
  String? contentValidator(String? val) {
    if(val == null || val.length == 0 ){
      return '값을 입력하세요';
    }
    return null;
  }
}
