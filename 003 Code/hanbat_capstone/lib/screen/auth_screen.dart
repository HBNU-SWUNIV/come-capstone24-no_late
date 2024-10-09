import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hanbat_capstone/services/category_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  String _phoneNumber = '';
  bool _isLogin = true;
  late CategoryService categoryService;

  @override
  void initState() {
    super.initState();
    categoryService = CategoryService();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success;

      try {
        if (!_isLogin) {
          // 회원가입 시 이메일 중복 확인
          bool isEmailInUse = await authProvider.isEmailAlreadyInUse(_email);
          if (isEmailInUse) {
            if (mounted) {
              _showErrorDialog('이미 사용 중인 이메일 입니다.');
            }
            return;
          }
        }

        if (_isLogin) {
          success = await authProvider.signIn(_email, _password);
        } else {
          success =
              await authProvider.signUp(_email, _password, _name, _phoneNumber);
        }

        if (success) {
          if (mounted) {
            // 로그인/회원가입 성공 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_isLogin ? '로그인 성공' : '회원가입 성공')),
            );
          }
        } else {
          if (mounted) {
            // 실패 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.errorMessage)),
            );
          }
        }
      } catch (e) {
        print('Error in _submitForm: $e');
        if (mounted) {
          _showErrorDialog('오류가 발생했습니다: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '로그인' : '회원가입')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: '이메일'),
                validator: (value) => value!.isEmpty ? '이메일을 입력하세요' : null,
                onSaved: (value) => _email = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? '6자 이상의 비밀번호를 입력하세요' : null,
                onSaved: (value) => _password = value!,
              ),
              if (!_isLogin) ...[
                TextFormField(
                  decoration: InputDecoration(labelText: '이름'),
                  validator: (value) => value!.isEmpty ? '이름을 입력하세요' : null,
                  onSaved: (value) => _name = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: '전화번호'),
                  validator: (value) => value!.isEmpty ? '전화번호를 입력하세요' : null,
                  onSaved: (value) => _phoneNumber = value!,
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                child: Text(_isLogin ? '로그인' : '회원가입'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.lightBlue[900],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: _submitForm,
              ),
              TextButton(
                child: Text(_isLogin ? '회원가입' : '로그인'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlue[900],
                ),
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //에러 다이얼로그
  void _showErrorDialog(String message) {
    if (!mounted) return; // mounted상태확인 (화면 활성화 여부 확인)
    print('Showing dialog with message: $message'); // 디버그 출력 추가
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('알림'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    ).then((_) => print('Dialog closed')); // 다이얼로그가 닫힐 때 디버그 출력
  }
}
