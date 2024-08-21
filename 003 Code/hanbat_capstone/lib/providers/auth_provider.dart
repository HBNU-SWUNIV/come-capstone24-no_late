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
      _errorMessage = e.toString();
      print(e.toString());
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
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      _errorMessage = e.toString();
      print(e.toString());
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}