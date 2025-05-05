import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'home.dart';

class SustainabilityAnalysisPage extends StatefulWidget {
  final String ingredients;
  final String companyOrWebsite;

  SustainabilityAnalysisPage({required this.ingredients, required this.companyOrWebsite});

  @override
  _SustainabilityAnalysisPageState createState() =>
      _SustainabilityAnalysisPageState();
}

class _SustainabilityAnalysisPageState extends State<SustainabilityAnalysisPage> {
  final String apiKey = 'API_KEY';
  String? result;
  bool isLoading = false;
  int sustainabilityScore = 50;
  List<Map<String, String>> breakdown = [];

  @override
  void initState() {
    super.initState();
    _analyzeIngredients(widget.ingredients, widget.companyOrWebsite);
  }

  Future<void> _analyzeIngredients(String ingredients, String company) async {
    if (ingredients.isEmpty) return;
    setState(() => isLoading = true);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=$apiKey');

    Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": """
              Analyze the following list of food ingredients for sustainability based on:
              - Local sourcing (locally sourced ingredients are preferred, but they don't have to be hyper-local. Same state is good.)
              - Fair labor practices (ingredients with Fair Trade, B-Corp certifications, etc.)
              - Ecological impact (organic, regenerative agriculture)
              - Humane sourcing (ethical animal welfare practices for meat, dairy, eggs)
              You MUST check the company website listed below to make all ratings personal to the company that created the product. Do not generalize ingredients as a certain sustainability, because the sourcing of the ingredients matters most. Check the company's website for information on how they source their ingredients.
              
              Please provide an overall sustainability score from 0 to 100 and a breakdown for each of the following categories:
              
              Local: Ingredients sourced locally or regionally score higher. Evaluate based on geographical sourcing information.
              Fair: Evaluate whether ingredients have certifications like Fair Trade, Rainforest Alliance, or B-Corp, or if there are known labor issues in the sourcing process.
              Ecological: Ingredients grown or produced using sustainable or organic farming methods. Check if the ingredient is from regenerative agriculture.
              Humane: For animal-based ingredients, check if they are ethically sourced (e.g., pasture-raised, free-range).
              BE HONEST, BUT BE NICE. DON'T SAY EVERYTHING IS UNSUSTAINABLE, HIGHLIGHT THE SUSTAINABLE ASPECTS OF A PRODUCT. This doesn't necessarily increase the score, but the descriptions should be nice.
              Still provide a description even if the category does not apply. Explain why it does not apply.
              
              Also provide a score_label for each category. "good" if it is sustainable, "meh" if it is ok, "bad" if it is unsustainable, and "n/a" if it is not applicable
              
              Ingredients: $ingredients
              Company: $company
              
              Example JSON Output:
              {
                "score": 85,
                "breakdown": [
                  { "title": "Local", "description": "Sourced locally from farms in the region.", "score_label": "good" },
                  { "title": "Fair", "description": "Fair Trade certified.", "score_label": "good" },
                  { "title": "Ecological", "description": "Produced using organic farming methods.", "score_label": "good" },
                  { "title": "Humane", "description": "Ethically sourced, pasture-raised.", "score_label": "good" }
                ]
              }
            """
            }
          ]
        }
      ]
    };

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data.containsKey("candidates")) {
          String responseText = data["candidates"][0]["content"]["parts"][0]["text"];

          // extracting the JSON portion using regex
          RegExp jsonRegex = RegExp(r'\{[\s\S]*\}', multiLine: true);
          Match? jsonMatch = jsonRegex.firstMatch(responseText);
          if (jsonMatch == null) {
            throw FormatException("valid json was not found in the response.");
          }

          String jsonString = jsonMatch.group(0)!;

          Map<String, dynamic> parsedData = jsonDecode(jsonString);

          setState(() {
            sustainabilityScore = (parsedData["score"] as int).clamp(0, 100);
            breakdown = List<Map<String, String>>.from(
                parsedData["breakdown"].map((item) => {
                  "title": item["title"].toString(),
                  "description": item["description"].toString(),
                  "score_label": item["score_label"].toString()
                }));
            isLoading = false;
          });
        } else {
          throw FormatException("unexpected api response format.");
        }
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        result = "Error: $e";
        isLoading = false;
      });
    }
  }

  Color _getOutlineColor(String label) {
    print(label);
    switch (label) {
      case 'good':
        return Colors.green;
      case 'meh':
        return Colors.orange;
      case 'bad':
        return Colors.red;
      default:
        return Colors.blueAccent;
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "how the scoring works",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF283618),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "this score follows the *real food challenge*, which promotes responsible food choices by evaluating sustainability, ethical sourcing, and ecological practices.",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  "ratings are based on four categories:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                _buildBullet("• local – ingredients are sourced locally or regionally."),
                _buildBullet("• fair – fair labor practices or certifications like Fair Trade/B-Corp."),
                _buildBullet("• ecological – organic, sustainable, or regenerative farming methods."),
                _buildBullet("• humane – ethically sourced animal-based ingredients (e.g., pasture-raised)."),
                SizedBox(height: 20),
                Text(
                  "⚠️ disclaimer:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "the score relies on the company’s publicly available data. if a company lacks detailed sourcing information online, the rating may be less accurate.",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF283618),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text("close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          's u s t a i n a b i l i t y    a n a l y s i s',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF283618),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage(initialTab: 1)),
                  (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Color(0xFF283618)),
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: Icon(Icons.flag, color: Color(0xFF283618)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage(initialTab: 3)),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isLoading) ...[
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFd62828),
                        Color(0xffff571d),
                        Color(0xFFfcbf49),
                        Color(0xFF36FF29)
                      ],
                      stops: [0.0, 0.33, 0.66, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: (sustainabilityScore / 100) *
                            MediaQuery.of(context).size.width *
                            0.8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "sustainability score: $sustainabilityScore",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              isLoading
                  ? Center(
                child: CircularProgressIndicator(),
              )
                  : breakdown.isNotEmpty
                  ? Column(
                children: breakdown
                    .map((section) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getOutlineColor(section['score_label']!),
                      width: 2.0,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['title']!,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        section['description']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              )
                  : const Text(
                  "sorry, something went wrong! please try again later."),
            ],
          ),
        ),
      ),
    );
  }
}
