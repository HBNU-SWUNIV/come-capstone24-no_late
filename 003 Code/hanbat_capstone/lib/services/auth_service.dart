import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 추가: authStateChanges getter
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 회원가입
  Future<UserModel?> signUp(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Firestore에 사용자 정보 저장
        UserModel newUser = UserModel(
            email: email,
            name: name,
            phoneNumber: phoneNumber
        );
        await _firestore.collection('user').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print("Error during sign up in AuthService: $e");
      if (e is FirebaseAuthException) {
        print("Firebase Auth Error Code: ${e.code}");
        print("Firebase Auth Error Message: ${e.message}");
        throw e;  // 오류를 상위로 전파
      }
      throw e;  // FirebaseAuthException이 아닌 경우에도 오류 전파
    }
    return null;
  }

  // 로그인
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('user').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print("Error during sign in: $e");
    }
    return null;
  }

  //이메일 중복 체크 메서드
  Future<bool> isEmailAlreadyInUse(String email) async {
    try {
      final result = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return result.isNotEmpty;
    } catch (e) {
      print("Error checking email existence: $e");
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}