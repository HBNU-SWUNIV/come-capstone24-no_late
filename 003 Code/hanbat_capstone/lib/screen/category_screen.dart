import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/model/category_model.dart';
import 'package:hanbat_capstone/providers/auth_provider.dart';
import 'package:hanbat_capstone/services/category_service.dart';
import 'package:provider/provider.dart';
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
  late CategoryService categoryService;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    categoryService = CategoryService();  // 초기화
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // 로그인한 사용자 정보 가져오기
    _userId = FirebaseAuth.instance.currentUser?.uid;

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
                            await addCategory(_userId!);
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
                  .where('userId', isEqualTo: _userId!)
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
                    itemBuilder: (context, index){
                      final category = categories[index];

                      return Dismissible(
                          key: ObjectKey(category.categoryId),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (DismissDirection direction) async {
                            if (category.defaultYn != 'Y') {
                              // 카테고리 삭제
                              await categoryService.deleteCategory(category.categoryId);
                            } else {
                              setState(() {});
                            }
                          },
                          confirmDismiss: (direction) async {
                            if (category.defaultYn == 'Y') {
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
  Future<void> addCategory(String userId) async {
    final categoryName = _contentController.text;
    if (categoryName.isEmpty) return ;

    final categoryModel = CategoryModel(
        categoryId: Uuid().v4(),
        userId: userId,
        categoryName: categoryName,
        colorCode: '0xFF000000',
        defaultYn : 'N'
    );

    await categoryService.addCategory(categoryModel);

    _contentController.clear();
  }

  /**
   * 카테고리 색상 변경
   */
  Future<void> updateCategoryColor(CategoryModel categoryModel, Color color) async {
    await categoryService.updateCategoryColor(categoryModel, color);
  }

  /**
   * 카테고리 색상 선택 팝업
   */
  void pickColor(BuildContext context, CategoryModel categoryModel) {
    final mainColor = Colors.lightBlue[900]!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더
                Container(
                  padding: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.palette, color: mainColor),
                      SizedBox(width: 8),
                      Text(
                        '색상 선택',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 컬러 피커
                Container(
                  height: 300,
                  margin: EdgeInsets.symmetric(vertical: 20),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: Color(int.parse(categoryModel.colorCode)),
                      onColorChanged: (color) {
                        setState(() {
                          _pickerColor = color;
                        });
                      },
                      layoutBuilder: (context, colors, child) {
                        return Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: colors.map((color) {
                              return Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _pickerColor == color ? mainColor : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: child(color),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      itemBuilder: (color, isSelected, onSelect) {
                        return InkWell(
                          onTap: onSelect,
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 버튼 영역
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await updateCategoryColor(categoryModel, _pickerColor);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0, // 그림자 제거
                      ),
                      child: Text(
                        '저장',
                        style: TextStyle(
                          color: Colors.white, // 텍스트 색상을 흰색으로 변경
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
