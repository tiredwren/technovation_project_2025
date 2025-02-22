import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SustainabilityScanner extends StatefulWidget {
  @override
  _SustainabilityScannerState createState() => _SustainabilityScannerState();
}

class _SustainabilityScannerState extends State<SustainabilityScanner> {
  TextEditingController ingredientsController = TextEditingController();
  String? result;
  bool isLoading = false;

  Future<void> analyzeIngredients() async {
    if (ingredientsController.text.isEmpty) return;
    setState(() => isLoading = true);

    String apiKey = 'AIzaSyAeGlNea1cqf-s6iob8glos_8pxsDGlepo';
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey');

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
              
              Assign a sustainability score from 0 to 100, where 100 is the most sustainable. Provide a brief justification.
              
              Ingredients: ${ingredientsController.text}
              
              Respond in JSON format: {"score": number, "justifications": ["reason1", "reason2", ...]}.
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

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data.containsKey("candidates")) {
          setState(() {
            result = data["candidates"][0]["content"]["parts"][0]["text"];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sustainability Scanner")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: ingredientsController,
                decoration: InputDecoration(labelText: "Enter Ingredients"),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: analyzeIngredients,
                child: isLoading ? CircularProgressIndicator() : Text("Analyze"),
              ),
              SizedBox(height: 20),
              result != null ? Text("Result: $result") : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
