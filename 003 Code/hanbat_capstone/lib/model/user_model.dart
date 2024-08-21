/**
 * 사용자 모델
 */
class UserModel {
  final String? userId;  // userId를 옵셔널로 변경
  final String email;
  final String name;
  final String phoneNumber;

  UserModel({
    this.userId,  // userId를 옵셔널 매개변수로 변경
    required this.email,
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}