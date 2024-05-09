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
}
