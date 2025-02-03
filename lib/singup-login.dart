import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupLogin extends StatefulWidget {
  const SignupLogin({super.key});

  @override
  State<SignupLogin> createState() => _SignupLoginState();
}

class _SignupLoginState extends State<SignupLogin> {
  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> _onLogin(LoginData data) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: data.name, password: data.password);
      return null; // successfully logged in
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
  }

  Future<String?> _onSignup(SignupData data) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: data.name!, password: data.password!);
      return null; // successfully signed-up
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
  }

  Future<String?> _onRecoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null; // password reset email sent
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        onLogin: _onLogin,
        onSignup: _onSignup,
        onRecoverPassword: _onRecoverPassword,
        theme: LoginTheme(
          primaryColor: Color(0xFF283618),
          buttonTheme: LoginButtonTheme(backgroundColor: Color(0xFF606c38)),
        ),
      ),
    );
  }
}
