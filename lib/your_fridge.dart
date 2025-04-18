import 'package:ai_recipe_generation/recipes_list.dart';
import 'package:ai_recipe_generation/scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'recipe.dart';

class GenerateRecipes extends StatefulWidget {
  final void Function(List<String>)? onRecipesGenerated;

  GenerateRecipes({this.onRecipesGenerated});
  @override
  _GenerateRecipesState createState() => _GenerateRecipesState();
}

class _GenerateRecipesState extends State<GenerateRecipes> {
  User? user = FirebaseAuth.instance.currentUser;
  List<String> ingredients = [];
  List <String> expirationDates = [];
  List<String> allergies = [];
  List<bool> selectedIngredients = [];
  List<bool> selectedAllergies = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Center(
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_menu, size: 50, color: Color(0xFF606C38)),
                    const SizedBox(height: 12),
                    Text(
                      "ready to cook?",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF283618),
                      ),
                    ),
            
                    const SizedBox(height: 12),
                    _buildCardWrapper(
                      TextField(
                        controller: dietaryRestrictionsController,
                        decoration: const InputDecoration(
                          labelText: 'Other Allergies/Dietary Restrictions',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
            
                    _buildCardWrapper(
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Preferred Cuisine Type',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() {
                            cuisineType = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16,),
                    Text(
                      "Tap below to generate recipes using your selected ingredients. We'll make sure to avoid your listed allergies!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: ()  {
                            Navigator.of(context).pop(); // close dialog
                            generateRecipe(); // call your generate function
                          },
                          child: Text("create recipes", style: GoogleFonts.poppins()),
                        )),
                    SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFDDA15E)),
                            onPressed: () {
                              Navigator.of(context).pop(); // close dialog
                            },
                            child: Text("cancel", style: GoogleFonts.poppins()),
                        )),
            
                      ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _fetchUserData() {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('ingredients')
          .orderBy('expiration_date', descending: false)
          .snapshots()
          .listen((snapshot) {
        List<String> fetchedIngredients = [];
        List<String> fetchedExpirationDates = [];

        for (var doc in snapshot.docs) {
          fetchedIngredients.add(doc.id); // Document ID is the ingredient name
          final timestamp = doc['expiration_date'] as Timestamp?;
          final date = timestamp?.toDate();
          final formattedDate = date != null ? DateFormat.yMMMd().format(date) : "no date";
          fetchedExpirationDates.add(formattedDate);
        }

        if (!mounted) return;
        setState(() {
          ingredients = fetchedIngredients;
          expirationDates = fetchedExpirationDates;
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
          fetchedAllergies.addAll(data.map((allergy) => allergy.toLowerCase()));
        }
        if (!mounted) return;
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
    if (!mounted) return;
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

    final apiKey = 'AIzaSyATi56IvBnjGbZ5qhFOLtAPl7mf5owwrdI';
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

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        if (widget.onRecipesGenerated != null) {
          widget.onRecipesGenerated!(generatedRecipes); // list of strings
        }
        // navigate to new page with recipes
        print(generatedRecipes);
      } else {
        _showError('error: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void inputIngredients() {
    print("in input");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(initialTab: 2)),
          (route) => false,
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

      if (!mounted) return;
      setState(() {
        ingredients.removeAt(index);
        selectedIngredients.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ingredient deleted')),
      );
    } catch (e) {
      print('error deleting ingredient: $e');
    }
  }

  void _updateIngredient(int index, String newIngredient) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Check for signed-in user

    String userId = user.uid;

    try {
      // get current id name
      String currentIngredient = ingredients[index].toLowerCase(); // lowercase to ensure all are grabbed

      // change id name to store it as the updated ingredient name
      if (newIngredient.toLowerCase() != currentIngredient) {
        // Delete the old document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('ingredients')
            .doc(currentIngredient)
            .delete();

        // Add new ingredient as a new document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('ingredients')
            .doc(newIngredient.toLowerCase()) // ingredient name = document id
            .set({
          'timestamp': FieldValue.serverTimestamp(), // timestamp to estimate expiration date
        });
      }

      if (!mounted) return;
      setState(() {
        // update local state with the new ingredient name
        if (newIngredient.toLowerCase() != currentIngredient) {
          ingredients[index] = newIngredient; // Update the local state
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ingredient updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error updating ingredient: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // — your existing scaffold stays exactly the same —
        Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "y o u r   f r i d g e",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFF283618),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF606C38),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: inputIngredients,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFFf1faee),
          ),
          backgroundColor: const Color(0xFFf1faee),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Select Ingredients'),
                        _buildCardWrapper(_buildCheckboxList(ingredients, selectedIngredients, expirationDates)),
                        const SizedBox(height: 20),
                        // we’ve removed the old in‐page loader; the overlay will handle it
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showCustomDialog,
                      child: const Text(
                        'create recipes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // — overlay barrier + spinner when loading —
        if (isLoading) ...[
          // prevent any interaction & dim background
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
          // centered loader
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFbc6c25)),
              ),
            ),
          ),
        ],
      ],
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

  Widget _buildCardWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }


  Widget _buildCheckboxList(List<String> items, List<bool> selections, List<String> expirationDates) {
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
                          if (!mounted) return;
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
                      Expanded(child:
                      Text(
                        expirationDates[index],
                        style: GoogleFonts.poppins(fontSize: 16),
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                      ),
                      )
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
