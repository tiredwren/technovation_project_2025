import 'dart:io';
import 'package:ai_recipe_generation/generate_recipes.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './ingredients_list.dart';

class GeminiImageProcessor extends StatefulWidget {
  @override
  _GeminiImageProcessorState createState() => _GeminiImageProcessorState();
}

class _GeminiImageProcessorState extends State<GeminiImageProcessor> {
  final String apiKey = 'AIzaSyCM8ZHUXiiC2_Pe4L6x_h4q714fgqDm6cY';
  late final GenerativeModel _model;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _textController.text = "Processing image...";
      });
      _processImage(_imageFile!);
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart("""Extract only the ingredients from this recipe image. 
          Do not include instructions or non-food items. Format the ingredients 
          as a comma-separated list."""),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      setState(() {
        _textController.text = response.text ?? 'No ingredients extracted.';
      });
    } catch (e) {
      setState(() {
        _textController.text = 'Error processing image: $e';
      });
    }
  }

  void _saveIngredients() async {
    final extractedText = _textController.text.trim(); // Trim any whitespace

    // Check if extractedText is empty
    if (extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No ingredients to save.")),
      );
      return; // Exit the function early if there are no ingredients
    }

    // Split and trim the ingredients from the extracted text
    final ingredients = extractedText.split(',').map((e) => e.trim()).toList();

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not signed in!")),
      );
      return;
    }

    String userId = user.uid;

    // Iterate through each ingredient and add it as a separate document
    for (String ingredient in ingredients) {
      if (ingredient.isNotEmpty) { // Ensure that the ingredient is not empty
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('ingredients')
              .doc(ingredient.toLowerCase()) // Use ingredient as document ID (in lowercase)
              .set({
            'timestamp': FieldValue.serverTimestamp(), // Add a timestamp field
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving ingredient: $e")),
          );
        }
      }
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ingredients saved to Firestore!")),
    );

    // Navigate to IngredientsPage after saving
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenerateRecipes()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingredient Scanner")),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("upload a receipt"),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("take image of receipt"),
                  ),
                ),
                _imageFile != null
                    ? Image.file(_imageFile!, height: 200)
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "extracted ingredients",
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveIngredients,
                    icon: const Icon(Icons.save),
                    label: const Text("save"),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerateRecipes(),
                      ),
                    ),
                    child: const Text("cancel"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
