/**
 * 카테고리 모델
 */
class CategoryModel {
  final String categoryId;      // 카테고리 ID
  final String userId;          // 사용자 ID
  final String categoryName;    // 카테고리명
  final String colorCode;       // 색상코드

  CategoryModel({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.colorCode
  });
}