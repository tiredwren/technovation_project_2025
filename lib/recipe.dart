import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecipePage extends StatelessWidget {
  final String recipe;
  RecipePage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    List<String> lines = recipe.split('\n');
    String title = lines.isNotEmpty ? lines[0].replaceAll('Title:', '') : 'Generated Recipe';
    List<String> ingredients = [];
    List<String> instructions = [];
    String cuisineType = '';
    String serves = '';
    List<String> nutrition = [];

    bool isIngredients = false;
    bool isInstructions = false;
    bool isNutrition = false;

    for (String line in lines.skip(1)) {
      if (line.toLowerCase().contains('ingredients:')) {
        isIngredients = true;
        isInstructions = false;
        isNutrition = false;
        continue;
      } else if (line.toLowerCase().contains('instructions:')) {
        isIngredients = false;
        isInstructions = true;
        isNutrition = false;
        continue;
      } else if (line.toLowerCase().contains('cuisine type')) {
        cuisineType = line.replaceAll('Cuisine Type:', '').trim();
        continue;
      } else if (line.toLowerCase().contains('serves:')) {
        serves = line.replaceAll('Serves:', '').trim();
        continue;
      } else if (line.toLowerCase().contains('nutrition:')) {
        isIngredients = false;
        isInstructions = false;
        isNutrition = true;
        continue;
      }

      if (isIngredients) {
        ingredients.add(line.trim());
      } else if (isInstructions) {
        instructions.add(line.trim());
      } else if (isNutrition) {
        nutrition.add(line.trim());
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Ingredients'),
              _buildList(ingredients),
              SizedBox(height: 10),
              _buildSectionTitle('Instructions'),
              _buildList(instructions),
              SizedBox(height: 10),
              _buildSectionTitle('Cuisine Type'),
              Text(cuisineType, style: GoogleFonts.poppins(fontSize: 16)),
              SizedBox(height: 10),
              _buildSectionTitle('Serving Size'),
              Text(serves, style: GoogleFonts.poppins(fontSize: 16)),
              SizedBox(height: 10),
              _buildSectionTitle('Nutrition Facts'),
              _buildList(nutrition),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Text(
          '$item',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      )).toList(),
    );
  }
}
