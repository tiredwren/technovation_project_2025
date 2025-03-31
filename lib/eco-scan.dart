import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analyze.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SustainabilityScanner extends StatefulWidget {
  @override
  _SustainabilityScannerState createState() => _SustainabilityScannerState();
}

class _SustainabilityScannerState extends State<SustainabilityScanner> {
  final String apiKey = 'AIzaSyCM8ZHUXiiC2_Pe4L6x_h4q714fgqDm6cY';
  late final GenerativeModel _model;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
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
          TextPart("""Extract the text in this image. This is a list of product ingredients, 
          so ensure the extracted text is logical. Don't include any text 
          that isn't in the uploaded image, like 'here's a list of the extracted ingredients
          from the provided page'"""),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      String extractedText = response.text ?? 'No text extracted.';

      setState(() {
        _textController.text = extractedText;
      });
    } catch (e) {
      setState(() {
        _textController.text = 'Error processing image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _imageFile != null
                  ? Image.file(_imageFile!, height: 200)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "ingredients list (edit as necessary)",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text("Pick from Gallery"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take a Photo"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _imageFile != null
                    ? () {
                  // Navigate to the analysis page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SustainabilityAnalysisPage(
                        ingredients: _textController.text,
                      ),
                    ),
                  );
                }
                    : null, // Disable button if no image has been uploaded
                child: const Text("Analyze Sustainability"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
