import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key : key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenSate();
}

class _ReviewScreenSate extends State<ReviewScreen> {

  DateTime currentDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          // 회고 텍스트 필드 추가
        },
        child: Icon(
          Icons.add_comment
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _DatePicker(
              currentDay : currentDay,
              onPressDate : onPressDate,
              onPressBackBtn : onPressBackBtn,
              onPressForwadBtn : onPressForwadBtn,
            ),
            _ReviewForm()
          ],
        ),
      ),
    );
  }

  void onPressDate(){
    showCupertinoDialog(  // 쿠퍼티노 다이얼로그 실행
      context: context,  // 보여줄 다이얼로그 빌드
      builder: (BuildContext context){
        return Align(
          alignment: Alignment.center,
          child: Container(
            color: Colors.white,
            height: 300,
            child: CupertinoDatePicker( // 날짜 선택하는 다이얼로그
              mode: CupertinoDatePickerMode.date,
              onDateTimeChanged: (DateTime date){
                setState(() {
                  currentDay = date;
                });
              },
            ),
          ),
        );
      },
      barrierDismissible: true, // 외부에서 탭할 경우 다이얼로그 닫기
    );
  }

  void onPressBackBtn(){
    setState(() {
      currentDay = currentDay.subtract(Duration(days: 1));
    });
  }

  void onPressForwadBtn(){
    setState(() {
      currentDay = currentDay.add(Duration(days: 1));
    });
  }
}

class _DatePicker extends StatelessWidget {

  final GestureTapCallback onPressDate;
  final GestureTapCallback onPressBackBtn;
  final GestureTapCallback onPressForwadBtn;
  final DateTime currentDay;

  _DatePicker({
    required this.onPressDate,
    required this.onPressBackBtn,
    required this.onPressForwadBtn,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton.icon(onPressed: onPressBackBtn, icon: Icon(Icons.arrow_back), label: Text("")),
        TextButton(onPressed: onPressDate, child: Text('${currentDay.year}.${currentDay.month}.${currentDay.day}')),
        TextButton.icon(onPressed: onPressForwadBtn, icon: Icon(Icons.arrow_forward), label: Text("")),
      ],
    );
  }
}

class _ReviewForm extends StatefulWidget {

  @override
  State createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    width: 1,
                    color: Colors.grey
                ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                        child: _TextField(
                          label: '제목',
                          isTitle: true,
                        )),
                    SizedBox(height:8),
                    Expanded(child: _TextField(
                      label: '내용',
                      isTitle: false,
                    ))
                  ],
                ),
              ),
            ),
      )
    );
  }
}

/**
 * 텍스트 입력하는 필드
 */
class _TextField extends StatelessWidget {

  final bool isTitle;
  final String label;

  const _TextField({
    required this.isTitle,
    required this.label,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600
          ),
        ),
        Expanded(
            child: TextFormField(
              cursorColor: Colors.grey,
              maxLines: isTitle ? 1 : null, // 제목 항목의 경우 한줄만
              expands: !isTitle,  // 제목 항목이 아닌 경우 한줄 이상 작성 가능
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[300],
              ),
            ))
      ],
    );
  }
}
