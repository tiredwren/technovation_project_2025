import 'package:ai_recipe_generation/recipes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'recipe.dart';

class GenerateRecipes extends StatefulWidget {
  @override
  _GenerateRecipesState createState() => _GenerateRecipesState();
}

class _GenerateRecipesState extends State<GenerateRecipes> {
  final List<String> ingredients = ['Tomato', 'Cheese', 'Lettuce', 'Chicken', 'Onion', 'Garlic', 'Beef', 'Tofu'];
  final List<String> allergies = ['Peanuts', 'Dairy', 'Gluten', 'Soy', 'Seafood', 'Eggs', 'Tree Nuts'];
  List<bool> selectedIngredients = List.filled(8, false);
  List<bool> selectedAllergies = List.filled(7, false);

  String cuisineType = '';
  TextEditingController dietaryRestrictionsController = TextEditingController();
  bool isLoading = false;
  List<String> recipes = [];

  Future<void> generateRecipe() async {
    setState(() {
      isLoading = true;
      recipes.clear();
    });

    List<String> chosenIngredients = [];
    List<String> chosenAllergies = [];

    for (int i = 0; i < selectedIngredients.length; i++) {
      if (selectedIngredients[i]) chosenIngredients.add(ingredients[i]);
    }

    for (int i = 0; i < selectedAllergies.length; i++) {
      if (selectedAllergies[i]) chosenAllergies.add(allergies[i]);
    }

    if (dietaryRestrictionsController.text.isNotEmpty) {
      chosenAllergies.add(dietaryRestrictionsController.text);
    }

    String prompt = '''
    You are a world-traveling chef creating multiple unique recipes.
    Recommend 12 different recipes using:
    - Ingredients: ${chosenIngredients.join(", ")}
    - Allergies to avoid: ${chosenAllergies.join(", ")}
    - Cuisine preference: ${cuisineType.isNotEmpty ? cuisineType : "Any"}

    Format for each:
    Title:
    Ingredients:
    - Ingredient1 (quantity)
    - Ingredient2 (quantity)
    Instructions:
    - Step1
    - Step2
    Cuisine Type:
    Serves: X
    Nutrition:
    - Calories: XX kcal
    - Fat: XX g
    - Carbs: XX g
    - Protein: XX g

    Separate each recipe with '###'
    ''';

    final apiKey = 'AIzaSyAeGlNea1cqf-s6iob8glos_8pxsDGlepo';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contents': [{'parts': [{'text': prompt}]}]}),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String responseText = data['candidates'][0]['content']['parts'][0]['text'];
        List<String> generatedRecipes = responseText.split('###').map((r) => r.trim()).toList();

        setState(() {
          isLoading = false;
        });

        // Navigate to new page with recipes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeListPage(recipes: generatedRecipes),
          ),
        );
      } else {
        _showError('Error: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Select Ingredients'),
                _buildCheckboxList(ingredients, selectedIngredients),
                SizedBox(height: 20),

                _buildSectionTitle('Select Allergies'),
                _buildCheckboxList(allergies, selectedAllergies),
                SizedBox(height: 10),

                TextField(
                  controller: dietaryRestrictionsController,
                  decoration: InputDecoration(
                    labelText: 'Other Allergies/Dietary Restrictions',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preferred Cuisine Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      cuisineType = value;
                    });
                  },
                ),
                SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: generateRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFbc6c25),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text('Generate Recipes', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFfefae0))),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFbc6c25)),
      ),
    );
  }

  Widget _buildCheckboxList(List<String> items, List<bool> selections) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return CheckboxListTile(
            title: Text(items[index], style: GoogleFonts.poppins(fontSize: 16)),
            value: selections[index],
            activeColor: Color(0xFFbc6c25),
            onChanged: (bool? value) {
              setState(() {
                selections[index] = value!;
              });
            },
          );
        }),
      ),
    );
  }
}

