import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'home.dart';

class RecipePage extends StatefulWidget {
  final String recipe;
  RecipePage({required this.recipe});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late String title;
  String cuisineType = '';
  String serves = '';
  List<String> ingredients = [], instructions = [], nutrition = [];
  Uint8List? aiImageBytes;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _parseRecipe();
    _fetchAIImage();
  }

  void _parseRecipe() {
    List<String> lines = widget.recipe.split('\n');
    title = lines.isNotEmpty ? lines[0].replaceAll('Title:', '').trim() : 'Generated Recipe';

    bool isIngredients = false, isInstructions = false, isNutrition = false;

    for (String line in lines.skip(1)) {
      if (line.toLowerCase().contains('ingredients:')) {
        isIngredients = true; isInstructions = false; isNutrition = false;
        continue;
      } else if (line.toLowerCase().contains('instructions:')) {
        isIngredients = false; isInstructions = true; isNutrition = false;
        continue;
      } else if (line.toLowerCase().contains('cuisine type')) {
        cuisineType = line.replaceAll('Cuisine Type:', '').trim();
        continue;
      } else if (line.toLowerCase().contains('serves:')) {
        serves = line.replaceAll('Serves:', '').trim();
        continue;
      } else if (line.toLowerCase().contains('nutrition:')) {
        isIngredients = false; isInstructions = false; isNutrition = true;
        continue;
      }

      if (isIngredients) ingredients.add(line.trim());
      else if (isInstructions) instructions.add(line.trim());
      else if (isNutrition) nutrition.add(line.trim());
    }
  }

  Future<void> _fetchAIImage() async {
    try {
      final response = await http.post(
        Uri.parse('https://some-cloud-function-url/generate-image'), // replace with firebase cloud function url
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': title}),
      );

      final data = jsonDecode(response.body);
      final base64 = data['image']; // the field must match what's returned by the function
      final imageBytes = base64Decode(base64);

      setState(() {
        aiImageBytes = imageBytes;
        isLoadingImage = false;
      });
    } catch (e) {
      print('Image fetch error: $e');
      setState(() => isLoadingImage = false);
    }
  }

  void _shareRecipe() {
    Share.share(widget.recipe);
  }

  Future<void> _saveRecipe() async {
    try {
      await FirebaseFirestore.instance.collection('saved_recipes').add({
        'title': title,
        'ingredients': ingredients,
        'instructions': instructions,
        'cuisineType': cuisineType,
        'serves': serves,
        'nutrition': nutrition,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipe saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving recipe')));
    }
  }

  Widget _buildSectionCard(String heading, List<String> content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFfffef2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFbc6c25))),
          const SizedBox(height: 8),
          ...content.map((e) => Text(e, style: GoogleFonts.poppins(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFfffef2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text("$label: ", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFFbc6c25))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf1faee),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage(initialTab: 0)),
                    (route) => false,
              ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareRecipe),
          IconButton(icon: Icon(Icons.bookmark), onPressed: _saveRecipe),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            isLoadingImage
                ? Center(child: CircularProgressIndicator())
                : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: aiImageBytes != null
                  ? Image.memory(aiImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 60, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard('🧂 Ingredients', ingredients),
            _buildSectionCard('📋 Instructions', instructions),
            _buildInfoTile('🍽 Cuisine Type', cuisineType),
            _buildInfoTile('👨‍👩‍👧‍👦 Serving Size', serves),
            _buildSectionCard('📊 Nutrition Facts', nutrition),
          ],
        ),
      ),
    );
  }
}
