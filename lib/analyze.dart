import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SustainabilityAnalysisPage extends StatefulWidget {
  final String ingredients;

  SustainabilityAnalysisPage({required this.ingredients});

  @override
  _SustainabilityAnalysisPageState createState() => _SustainabilityAnalysisPageState();
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
      appBar: AppBar(title: const Text('Sustainability Analysis')),
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
                        Color(0xFFfb5607),
                        Color(0xFFfcbf49),
                        Color(0xFF588157)
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
                  ? const Center(child: CircularProgressIndicator())
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['title']!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                  : const Text("Sorry, something went wrong! Please try again later."),
            ],
          ),
        ),
      ),
    );
  }
}
