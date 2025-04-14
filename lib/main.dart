import 'package:ai_recipe_generation/generate_recipes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai_recipe_generation/signup_login.dart';
import 'package:google_fonts/google_fonts.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFbc6c25),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(titleLarge: GoogleFonts.poppins(fontSize: 18, color: const Color(
            0xff3a6b40))),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            iconColor: Color(0xFFfefae0),
            foregroundColor: Color(0xFFfefae0),
            textStyle: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFFfefae0)),
            backgroundColor: const Color(0xFFbc6c25),
            padding: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            )
          )
        )
      ),
      home: SignupLogin(), // start with signup/login page
      routes: {
        '0': (context) => GenerateRecipes(),
        '1': (context) => SignupLogin(),
      },
    );
  }
}