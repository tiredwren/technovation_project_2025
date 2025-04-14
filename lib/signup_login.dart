import 'package:ai_recipe_generation/generate_recipes.dart';
import 'package:ai_recipe_generation/home.dart';
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
      Navigator.pushReplacement( // successfully logged in
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
    return null;
  }

  Future<String?> _onSignup(SignupData data) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: data.name!, password: data.password!);
      Navigator.pushReplacement(// successfully signed up
        context,
        MaterialPageRoute(builder: (context) => GenerateRecipes()),
      );
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
    return null;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: FlutterLogin(
                  onLogin: _onLogin,
                  onSignup: _onSignup,
                  onRecoverPassword: _onRecoverPassword,
                  headerWidget: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                      ),
                    ),
                  ),
                  theme: LoginTheme(
                    primaryColor: Color(0xFF283618),
                    accentColor: Color(0xFFbc6c25),
                    buttonTheme: LoginButtonTheme(
                      backgroundColor: Color(0xFF606c38),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}