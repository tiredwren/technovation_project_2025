import 'package:ai_recipe_generation/recipes_list.dart';
import 'package:ai_recipe_generation/scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  User? user = FirebaseAuth.instance.currentUser;
  List<String> ingredients = [];
  List<String> allergies = [];
  List<bool> selectedIngredients = [];
  List<bool> selectedAllergies = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('ingredients')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        List<String> fetchedIngredients = [];
        for (var doc in snapshot.docs) {
          fetchedIngredients.add(doc.id); // Document ID is the ingredient name
        }
        setState(() {
          ingredients = fetchedIngredients.toSet().toList();
          selectedIngredients = List.filled(ingredients.length, false);
        });
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('allergies')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        List<String> fetchedAllergies = [];
        for (var doc in snapshot.docs) {
          final data = List<String>.from(doc['allergies']);
          fetchedAllergies.addAll(data.map((allergy) => allergy.toLowerCase())); // Convert to lowercase
        }
        setState(() {
          allergies = fetchedAllergies.toSet().toList();
          selectedAllergies = List.filled(allergies.length, false);
        });
      });
    }
  }

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

    final apiKey = 'AIzaSyCM8ZHUXiiC2_Pe4L6x_h4q714fgqDm6cY';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=$apiKey');

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

  void inputIngredients(BuildContext context) {
    print("image processing");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeminiImageProcessor(),
      ),
    );
  }

  void _showEditDialog(String ingredient, int index) {
    final TextEditingController controller = TextEditingController(text: ingredient);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Ingredient'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Ingredient Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete Ingredient
                _deleteIngredient(index);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                // Update Ingredient
                if (controller.text.isNotEmpty) {
                  _updateIngredient(index, controller.text);
                }
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteIngredient(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Check for signed-in user

    String userId = user.uid;

    try {
      // Delete the ingredient document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ingredients')
          .doc(ingredients[index]) // Use the ingredient name as the document ID
          .delete();

      setState(() {
        ingredients.removeAt(index);
        selectedIngredients.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingredient deleted')),
      );
    } catch (e) {
      print('Error deleting ingredient: $e');
    }
  }

  void _updateIngredient(int index, String newIngredient) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Check for signed-in user

    String userId = user.uid;

    try {
      // Get the document ID (the current ingredient name)
      String currentIngredient = ingredients[index].toLowerCase(); // Make sure to use lowercase

      // Optionally, if you want to change the document ID itself, delete the old document and create a new one with the new ID
      if (newIngredient.toLowerCase() != currentIngredient) {
        // Delete the old document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('ingredients')
            .doc(currentIngredient) // Current ingredient as old document ID
            .delete();

        // Add new ingredient as a new document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('ingredients')
            .doc(newIngredient.toLowerCase()) // Use the new ingredient name as the document ID
            .set({
          'timestamp': FieldValue.serverTimestamp(), // Set timestamp for new ingredient
        });
      }

      setState(() {
        // Update the local state with the new ingredient name
        if (newIngredient.toLowerCase() != currentIngredient) {
          ingredients[index] = newIngredient; // Update the local state
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingredient updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ingredient: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 10)),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "y o u r    f r i d g e",
                    style: GoogleFonts.poppins(fontSize: 24),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF606C38),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        debugPrint("Plus button pressed");
                        inputIngredients(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Adjust spacing

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Select Ingredients'),
                    _buildCheckboxList(ingredients, selectedIngredients),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Other Specifications'),
                    _buildCheckboxList(allergies, selectedAllergies),
                    const SizedBox(height: 10),

                    TextField(
                      controller: dietaryRestrictionsController,
                      decoration: const InputDecoration(
                        labelText: 'Other Allergies/Dietary Restrictions',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: generateRecipe,
                    child: Text(
                      'create recipes',
                    ),
                  ),
                ),
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: selections[index],
                        onChanged: (bool? value) {
                          setState(() {
                            selections[index] = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          items[index],
                          style: GoogleFonts.poppins(fontSize: 16),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit Button
                TextButton(
                  onPressed: () {
                    _showEditDialog(items[index], index); // Show edit dialog
                  },
                  child: Text("Edit", style: TextStyle(color: Colors.blue)),
                ),
                // Delete Button
                TextButton(
                  onPressed: () {
                    _deleteIngredient(index); // Call delete function
                  },
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
