import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hanbat_capstone/const/colors.dart';
import 'package:hanbat_capstone/screen/category_screen.dart';

import 'time_range_setting_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late TextEditingController _contentController;
  Color _pickerColor = Color(0xff000000); // default

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        appBar: AppBar(
          title: Text('설정'),
          centerTitle: true,
        ),
        body: ListView(
          children: <Widget>[
            SizedBox(height: 15,),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: PRIMARY_COLOR,
                foregroundColor: COLOR_WHITE,
                child: Icon(Icons.person),
                radius: 30,
              ),
              title: Text('사용자 이름'), // TODO 세션처리 후 수정
              //subtitle: Text('개인정보 수정하기'),
              trailing: IconButton(onPressed: (){}, icon:Icon(Icons.logout)), //TODO 로그아웃 기능 추가 필요
              onTap: (){},
            ),
            SizedBox(height: 5,),
            Divider(),
            SizedBox(height: 5,),
            ListTile(
              leading: Icon(Icons.list, color: Colors.grey),
              title: Text('카테고리'),
              trailing: IconButton(onPressed: onTapCategoryMenu, icon:Icon(Icons.arrow_forward_ios)),
              onTap: onTapCategoryMenu,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.access_time, color: Colors.grey),
              title: Text('스케줄 시간 설정'),
              trailing: IconButton(onPressed: onTapTimeRangeMenu, icon:Icon(Icons.arrow_forward_ios)),
              onTap: onTapTimeRangeMenu,
            ),
          ],
        ));
  }

  void onTapCategoryMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryScreen(),
      ),
    ).then((value) {
      // 없음.
    });
  }
  void onTapTimeRangeMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeRangeSettingScreen(),
      ),
    );
  }
}
