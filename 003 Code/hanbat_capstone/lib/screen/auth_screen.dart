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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success;
      if (_isLogin) {
        success = await authProvider.signIn(_email, _password);
      } else {
        success = await authProvider.signUp(_email, _password, _name, _phoneNumber);
      }

      if (success) {
        // 로그인/회원가입 성공 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isLogin ? '로그인 성공' : '회원가입 성공')),
        );
      } else {
        // 실패 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage)),
        );
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
                validator: (value) => value!.length < 6 ? '6자 이상의 비밀번호를 입력하세요' : null,
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
                onPressed: _submitForm,
              ),
              TextButton(
                child: Text(_isLogin ? '회원가입으로 전환' : '로그인으로 전환'),
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
}