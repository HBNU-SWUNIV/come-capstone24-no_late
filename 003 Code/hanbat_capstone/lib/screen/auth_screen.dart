import 'package:flutter/material.dart';
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
  bool _isResetPassword = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isResetPassword) {
        await authProvider.sendPasswordResetEmail(_email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일로 비밀번호 재설정')),
        );
        setState(() {
          _isResetPassword = false;
        });
      } else if (_isLogin) {
        final success = await authProvider.signIn(_email, _password);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패')),
          );
        }
      } else {
        final success = await authProvider.signUp(_email, _password, _name, _phoneNumber);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 실패')),
          );
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해 주세요';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              if (!_isResetPassword) ...[
                TextFormField(
                  decoration: InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해 주세요';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
              ],
              if (!_isLogin && !_isResetPassword) ...[
                TextFormField(
                  decoration: InputDecoration(labelText: '이름'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '사용할 이름을 입력해 주세요';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: '전화번호'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '전화번호를 입력해 주세요';
                    }
                    return null;
                  },
                  onSaved: (value) => _phoneNumber = value!,
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isResetPassword ? '비밀번호 재설정' : (_isLogin ? '로그인' : '회원가입')),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _isResetPassword = false;
                  });
                },
                child: Text(_isLogin ? '회원가입' : '이미 가입을 한 경우'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isResetPassword = !_isResetPassword;
                    _isLogin = true;
                  });
                },
                child: Text(_isResetPassword ? '로그인으로 돌아가기' : '비밀번호를 잊으셨나요?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}