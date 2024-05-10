/**
 * 회고관리 모델
 */
class ReviewModel {
  final String reviewId;        // 회고 ID (YYYYMMDD-SEQ)
  final String userId;          // 사용자 ID
  final DateTime reviewDate;    // 회고 날짜
  final String reviewTitle;     // 회고 제목
  final String reviewContent;   // 회고 내용

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.reviewDate,
    required this.reviewTitle,
    required this.reviewContent,
  });

  /**
   * JSON으로부터 모델로 변환
   */
  ReviewModel.fromJson({
    required Map<String, dynamic> json,
  }) : reviewId = json['reviewId'],
        userId = json['userId'],
        reviewDate = json['reviewDate'],
        reviewTitle = json['reviewTitle'],
        reviewContent = json['reviewContent'];

  /**
   * 모델을 JSON으로 변환
   */
  Map<String, dynamic> toJson () {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'reviewDate': '${reviewDate.year}${reviewDate.month.toString().padLeft(2,'0')}${reviewDate.day.toString().padLeft(2,'0')}',
      'reviewTitle': reviewTitle,
      'reviewContent': reviewContent
    };
  }

  /**
   * 현재 모델을 특정 속성만 변환해서 새로 생성
   */
  ReviewModel copyWith({
    String? reviewId,
    String? userId,
    DateTime? reviewDate,
    String? reviewTitle,
    String? reviewContent,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      reviewDate: reviewDate ?? this.reviewDate,
      reviewTitle: reviewTitle ?? this.reviewTitle,
      reviewContent: reviewContent ?? this.reviewContent
    );
  }
}
