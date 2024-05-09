/**
 * 사용자 모델
 */
class UserModel {
  final String userId;          // 사용자 ID
  final String name;            // 이름
  final String phoneNumber;     // 전화번호

  UserModel({
    required this.userId,
    required this.name,
    required this.phoneNumber,
  });
}
