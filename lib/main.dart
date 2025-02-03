import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:technovation_project_2025/singup-login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFFbc6c25),
      ),
      home: SignupLogin(), // start with signup/login page
    );
  }
}
