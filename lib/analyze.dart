import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home.dart';

class SustainabilityAnalysisPage extends StatefulWidget {
  final String ingredients;

  SustainabilityAnalysisPage({required this.ingredients});

  @override
  _SustainabilityAnalysisPageState createState() =>
      _SustainabilityAnalysisPageState();
}

class _SustainabilityAnalysisPageState extends State<SustainabilityAnalysisPage> {
  final String apiKey = 'AIzaSyCM8ZHUXiiC2_Pe4L6x_h4q714fgqDm6cY';
  String? result;
  bool isLoading = false;
  int sustainabilityScore = 50;
  List<Map<String, String>> breakdown = [];

  @override
  void initState() {
    super.initState();
    _analyzeIngredients(widget.ingredients);
  }

  Future<void> _analyzeIngredients(String ingredients) async {
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
              - Carbon footprint
              - Deforestation impact
              - Water usage
              - Ethical sourcing
              - Processing level
              
              This is the criterion you should be going off of:
              
              Carbon Footprint:
              Evaluation: The AI assesses the greenhouse gas emissions associated with the production, transportation, and processing of each ingredient. Locally sourced ingredients usually receive higher scores due to reduced transportation emissions.
              Factors Considered:
              Type of agricultural practices (e.g., conventional vs. organic)
              Transportation distances
              Refrigeration and storage requirements
              Score Impact: 30%, low emissions → higher score
              
              Deforestation Impact:
              Evaluation: This category evaluates whether the cultivation of an ingredient contributes to deforestation, particularly in biodiversity hotspots. Ingredients linked to sustainable agricultural practices that avoid deforestation receive better scores.
              Factors Considered:
              Source of the ingredient (e.g., palm oil, soy, beef)
              Certifications such as Rainforest Alliance or Fair Trade
              Score Impact: 20%, high deforestation impact → higher score
              
              Water Usage:
              Evaluation: The AI looks at the amount of water required for growing and processing the ingredient. Ingredients that thrive in arid conditions or require significant irrigation typically receive lower scores.
              Factors Considered:
              Water consumption rates for crop growth
              Efficiency of irrigation methods
              Impact on local water sources and ecosystems
              Score Impact: 20% of score, high water usage → lower score
              
              Ethical Sourcing:
              Evaluation: This category assesses the labor practices involved in the sourcing of the ingredient. Ingredients sourced from farms with fair labor practices and respect for human rights score higher.
              Factors Considered:
              Certifications (e.g., Fair Trade)
              Reports of labor rights abuses
              Transparency in the supply chain
              Score Impact: 20%, more ethical sourcing → higher score
              
              Processing Level:
              Evaluation: The AI examines how processed the ingredient is, as highly processed foods tend to have a larger carbon footprint and may include artificial additives. Minimal processing usually scores higher due to fewer resources used and less waste.
              Factors Considered:
              Degree of processing (e.g., raw, minimally processed, heavily processed)
              Additives and preservatives
              Score Impact: 10%, high processing → lower score
              If there is heavy processing, say that processing is high. Not low.
                          
              Assign a sustainability score from 0 to 100, where 100 is the most sustainable. Provide a breakdown of each category **in valid JSON format** as a list of objects with 'title' and 'description'.
              
              Ingredients: $ingredients
              
              Example JSON Output:
              {
                "score": 85,
                "breakdown": [
                  { "title": "Carbon Footprint", "description": "Low due to locally sourced ingredients." },
                  { "title": "Water Usage", "description": "Moderate usage for irrigation." }
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

          // Extract the JSON portion using regex
          RegExp jsonRegex = RegExp(r'\{[\s\S]*\}', multiLine: true);
          Match? jsonMatch = jsonRegex.firstMatch(responseText);
          if (jsonMatch == null) {
            throw FormatException("No valid JSON found in response.");
          }

          String jsonString = jsonMatch.group(0)!;

          Map<String, dynamic> parsedData = jsonDecode(jsonString);

          setState(() {
            sustainabilityScore = (parsedData["score"] as int).clamp(0, 100);
            breakdown = List<Map<String, String>>.from(
                parsedData["breakdown"].map((item) => {
                  "title": item["title"].toString(),
                  "description": item["description"].toString(),
                }));
            isLoading = false;
          });
        } else {
          throw FormatException("Unexpected API response format.");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('s u s t a i n a b i l i t y    a n a l y s i s',),
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
                    "Sustainability Score: $sustainabilityScore",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xffff571d)), // Match the button color
                ),
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
