/**
 * 카테고리 모델
 */
class CategoryModel {
  final String categoryId;      // 카테고리 ID
  final String userId;          // 사용자 ID
  final String categoryName;    // 카테고리명
  final String colorCode;       // 색상코드
  final String? defaultYn;

  CategoryModel({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.colorCode,
    this.defaultYn
  });

  /**
   * JSON으로부터 모델로 변환
   */
  CategoryModel.fromJson({
    required Map<String, dynamic> json,
  }) : categoryId = json['categoryId'],
       userId = json['userId'],
       categoryName = json['categoryName'],
       colorCode = json['colorCode'],
       defaultYn = json['defaultYn'] ?? 'N';

  /**
   * 모델을 JSON으로 변환
   */
  Map<String, dynamic> toJson(){
    return {
      'categoryId' : categoryId,
      'userId' : userId,
      'categoryName' : categoryName,
      'colorCode' : colorCode,
      'defaultYn' : defaultYn ?? 'N'
    };
  }

  /**
   * 모델을 특정 속성만 변환해서 새로 생성
   */
  CategoryModel copyWith({
    String? categoryId,
    String? userId,
    String? categoryName,
    String? colorCode,
    String? defaultYn
  }) {
    return CategoryModel(
        categoryId: categoryId ?? this.categoryId,
        userId: userId ?? this.userId,
        categoryName: categoryName ?? this.categoryName,
        colorCode: colorCode ?? this.colorCode,
        defaultYn: defaultYn ?? this.defaultYn ?? 'N'
    );
  }
}