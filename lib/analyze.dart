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
  int sustainabilityScore = 50; // default score

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
              
              Assign a sustainability score from 0 to 100, where 100 is the most sustainable. Provide a brief justification, but no areas for improvement.
              
              Ingredients: $ingredients
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
          String responseText =
          data["candidates"][0]["content"]["parts"][0]["text"];
          RegExp scoreRegex = RegExp(r'\b(\d{1,3})\b');
          Match? match = scoreRegex.firstMatch(responseText);
          int extractedScore = match != null ? int.parse(match.group(0)!) : 50;

          setState(() {
            result = responseText;
            sustainabilityScore =
                extractedScore.clamp(0, 100); // to make sure the score stays within range
            isLoading = false;
          });
        } else {
          setState(() {
            result = "Error: Unexpected API response format.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          result = "Error: ${response.statusCode} - ${response.body}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
        isLoading = false;
      });
    }
  }

  List<TextSpan> _parseBoldText(String text) {
    List<TextSpan> spans = [];
    RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (Match match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Eco Scan")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
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
                  : result != null
                  ? RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: Colors.black, fontSize: 16),
                  children: _parseBoldText(result!),
                ),
              )
                  : const Text("No analysis available."),
            ],
          ),
        ),
      ),
    );
  }
}
