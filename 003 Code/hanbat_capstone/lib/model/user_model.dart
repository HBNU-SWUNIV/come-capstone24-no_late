/**
 * 사용자 모델
 */
class UserModel {
  final String email;  // 이메일 (ID로 사용)
  final String name;
  final String phoneNumber;
  bool isPhoneVerified;  // 전화번호 인증 여부

  UserModel({
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.isPhoneVerified = false,
  });

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  // Firestore 문서에서 UserModel 생성
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      isPhoneVerified: map['isPhoneVerified'] ?? false,
    );
  }
}
