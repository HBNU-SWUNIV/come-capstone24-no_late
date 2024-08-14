import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../model/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // 추가: authStateChanges getter
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _user = null;
      } else {
        // Firestore에서 최신 사용자 데이터를 가져오는 로직을 여기에 추가할 수 있습니다.
        // 지금은 간단히 이메일만 설정합니다.
        _user = UserModel(email: firebaseUser.email!, name: '', phoneNumber: '');
      }
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password, String name, String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? user = await _authService.signUp(email, password, name, phoneNumber);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserModel? user = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // 전화번호 인증 메서드 (기본 구조만)
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _authService.verifyPhoneNumber(phoneNumber);
  }
}