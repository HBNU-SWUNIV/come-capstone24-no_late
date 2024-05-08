/**
 * 회고관리 모델
 */
class ReviewModel {
  final String reviewId;
  final String userId;
  final DateTime reviewDate;
  final String reviewTitle;
  final String reviewContent;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.reviewDate,
    required this.reviewTitle,
    required this.reviewContent,
  });
}