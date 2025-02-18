import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipePage extends StatelessWidget {
  final String recipe;
  RecipePage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Match background color
      appBar: AppBar(
        title: Text('Generated Recipe', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              recipe,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
