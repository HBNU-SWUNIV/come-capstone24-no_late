import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hanbat_capstone/model/category_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hanbat_capstone/const/colors.dart';

/**
 * 카테고리 목록 화면
 * - 카테고리 추가, 수정, 삭제
 */
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late TextEditingController _contentController;
  Color _pickerColor = CATEGORY_DEF_PICKER_COLOR; // default

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
          title: const Text('카테고리'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          foregroundColor: COLOR_WHITE,
          backgroundColor: PRIMARY_COLOR,
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('카테고리 추가'),
                    backgroundColor: COLOR_WHITE,
                    titleTextStyle: ALERT_DIALOG_TITLE_TEXTSTYLE,
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: _contentController,
                            decoration: InputDecoration(
                                hintText: "카테고리 이름",
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: PRIMARY_COLOR!),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: PRIMARY_COLOR!, width: 2)
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ERROR_COLOR),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: ERROR_COLOR, width: 2),
                              )
                            ),
                            cursorColor: PRIMARY_COLOR,
                            cursorErrorColor: ERROR_COLOR,
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('취소', style: TextStyle(color: PRIMARY_COLOR),)),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PRIMARY_COLOR,
                            foregroundColor: COLOR_WHITE,
                          ),
                          onPressed: () async {
                            await addCategory();
                            Navigator.of(context).pop();
                          },
                          child: Text('저장'))
                    ],
                  );
                });
          },
          child: Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: SafeArea(
            child: Column(
          children: [
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('category')
                  //.where('userId', isEqualTo: 'yjkoo') //TODO 추가해야함
                  .orderBy('categoryId', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('카테고리 정보를 가져오지 못했습니다.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data!.docs.isNotEmpty) {
                  final categories = snapshot.data!.docs
                      .map((QueryDocumentSnapshot e) => CategoryModel.fromJson(
                          json: (e.data() as Map<String, dynamic>)))
                      .toList();

                  // 카테고리 목록 조회
                  return ListView.builder(
                    padding: EdgeInsets.all(5),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return Dismissible(
                          key: ObjectKey(category.categoryId),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (DismissDirection direction) {
                            // 카테고리 삭제
                            // 카테고리 아이디가 plan인 경우, 삭제안되게 함.
                            // TODO 앱 실행 시 카테고리 컬렉션에 일정카테고리가 있는지 체크 후 없으면 default 로 추가해야함.
                            if (category.categoryName != '일정') {
                              FirebaseFirestore.instance
                                  .collection('category')
                                  .doc(category.categoryId)
                                  .delete();
                            } else {
                              setState(() {});
                            }
                          },
                          confirmDismiss: (direction) async {
                            if (category.categoryName == '일정') {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('일정 카테고리는 삭제할 수 없습니다.'),
                              ));
                              return false;
                            }
                            return true;
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(width: 1, color: Colors.grey)),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        pickColor(context, category);
                                      },
                                      icon: Icon(Icons.circle),
                                      color:
                                          Color(int.parse(category.colorCode)),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                        child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(category.categoryName),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ));
                    },
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )),
          ],
        )));
  }

  /**
   * 카테고리 추가
   */
  Future<void> addCategory() async {
    final categoryName = _contentController.text;
    if (categoryName.isEmpty) return ;

    final categoryModel = CategoryModel(
        categoryId: Uuid().v4(),
        userId: 'yjkoo', // TODO 하드코딩 수정필요
        categoryName: categoryName,
        colorCode: '0xFF000000');

    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection('category')
        .doc(categoryModel.categoryId)
        .set(categoryModel.toJson());

    _contentController.clear();
  }

  /**
   * 카테고리 색상 변경
   */
  Future<void> updateCategoryColor(
      CategoryModel categoryModel, Color color) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('category')
        .doc(categoryModel.categoryId)
        .update({'colorCode': color.value.toString()});
  }

  /**
   * 카테고리 색상 선택 팝업
   */
  void pickColor(BuildContext context, CategoryModel categoryModel) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('색상 선택'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: Color(int.parse(categoryModel.colorCode)),
                onColorChanged: (color) {
                  setState(() {
                    _pickerColor = color;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('취소')),
              ElevatedButton(
                  onPressed: () async {
                    await updateCategoryColor(categoryModel, _pickerColor);
                    Navigator.of(context).pop();
                  },
                  child: Text('저장'))
            ],
          );
        });
  }
}
