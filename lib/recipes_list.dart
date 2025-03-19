import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe.dart';

class RecipeListPage extends StatelessWidget {
  final List<String> recipes;

  RecipeListPage({required this.recipes});

  @override
  Widget build(BuildContext context) {
    // filter the recipes to include only those with a valid title
    List<String> validRecipes = recipes.where((recipe) {
      List<String> lines = recipe.split('\n');
      return lines.isNotEmpty && lines[0].startsWith('Title:');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Generated Recipes", style: TextStyle(color: Color(0xFFfefae0))),
        backgroundColor: Color(0xFF283618),
      ),
      backgroundColor: Color(0xFFf1faee),
      body: validRecipes.isEmpty
          ? Center(child: Text(
          "no valid recipes available; please try again with different inputs!.",
          style: GoogleFonts.poppins(fontSize: 18)))
          : ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        itemCount: validRecipes.length,
        itemBuilder: (context, index) {
          List<String> lines = validRecipes[index].split('\n');
          String title = lines[0].replaceAll('Title:', '').trim();

          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              title: Text(
                  title, style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward, color: Color(0xFF606c38)),
              onTap: () {
                // navigate to RecipePage with the selected recipe
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipePage(recipe: validRecipes[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
