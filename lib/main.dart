import 'package:ai_recipe_generation/generate_recipes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai_recipe_generation/signup_login.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      routes: {
        '0': (context) => GenerateRecipes(),
        '1': (context) => SignupLogin(),
      },
    );
  }
}