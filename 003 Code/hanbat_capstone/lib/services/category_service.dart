import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanbat_capstone/model/category_model.dart';
import 'package:uuid/uuid.dart';

/**
 * 카테고리 기능
 */
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /**
   * 카테고리 조회
   */
  Future<List<CategoryModel>> getCategoriesByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('category')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        return CategoryModel.fromJson(json: doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('카테고리 조회 중 오류가 발생하였습니다. \n오류내용 : $e');
      throw e;
    }
  }

  /**
   *  카테고리 등록
   */
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _firestore.collection('category')
          .doc(category.categoryId)
          .set(category.toJson());
    } catch (e) {
      print('카테고리 등록 중 오류가 발생하였습니다.\n오류내용: $e');
      throw e;
    }
  }

  Future<void> addNewCategory(String uid) async {
    try {
      CategoryModel newCategory = CategoryModel(
          categoryId: Uuid().v4(),
          userId: uid,
          categoryName: '일정',
          colorCode: '0xFF000000',
          defaultYn: 'Y'
      );

      addCategory(newCategory);
    } catch (e) {
      print('카테고리 등록 중 오류가 발생하였습니다.\n오류내용: $e');
      throw e;
    }
  }

  /**
   * 카테고리 삭제
   */
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('category')
          .doc(categoryId)
          .delete();
    } catch (e) {
      print('카테고리 삭제 중 오류가 발생하였습ㅈ니다.\n오류내용 : $e');
      throw e;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore.collection('category')
          .doc(category.categoryId)
          .update({

      });
    } catch (e) {
      print('카테고리 색상 저장 중 오류가 발생하였습니다.\n오류내용 : $e');
    }
  }

  /**
   * 카테고리 색상 변경
   */
  Future<void> updateCategoryColor(CategoryModel category, Color color) async {
    try {
      await _firestore.collection('category')
          .doc(category.categoryId)
          .update({
        'colorCode' : color.value.toString()
      });
    } catch (e) {
      print('카테고리 색상 저장 중 오류가 발생하였습니다.\n오류내용 : $e');
    }
  }


}