import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../model/user_model.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get user => _user;
  String? get userId => _user?.userId; // 사용자 id 변환
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<bool> signUp(String email, String password, String name, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? user = await _authService.signUp(email, password, name, phoneNumber);
      _isLoading = false;
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = '이미 사용 중인 이메일 주소입니다.';
            break;
          case 'weak-password':
            _errorMessage = '비밀번호가 너무 약합니다.';
            break;
          default:
            _errorMessage = '회원가입 중 오류가 발생했습니다: ${e.message}';
        }
      } else {
        _errorMessage = '알 수 없는 오류가 발생했습니다: $e';
      }
      print('Error in AuthProvider signUp: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? user = await _authService.signIn(email, password);
      _isLoading = false;
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      } else {
        _errorMessage = '이메일이나 비밀번호가 올바르지 않습니다.';
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = '등록되지 않은 이메일입니다.';
            break;
          case 'wrong-password':
            _errorMessage = '비밀번호가 올바르지 않습니다.';
            break;
          case 'invalid-email':
            _errorMessage = '유효하지 않은 이메일 형식입니다.';
            break;
          default:
            _errorMessage = '로그인 중 오류가 발생했습니다: ${e.message}';
        }
      } else {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      }
      print('Error in AuthProvider signIn: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  //이메일 중복 체크
  Future<bool> isEmailAlreadyInUse(String email) async {
    return await _authService.isEmailAlreadyInUse(email);
  }

  Future<void> signOut() async { 
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  //사용자 정보 로드 메서드
  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data()!);
          notifyListeners();
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }
}