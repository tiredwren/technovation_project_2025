import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiImageProcessor extends StatefulWidget {
  @override
  _GeminiImageProcessorState createState() => _GeminiImageProcessorState();
}

class _GeminiImageProcessorState extends State<GeminiImageProcessor> {
  final String apiKey = 'AIzaSyAeGlNea1cqf-s6iob8glos_8pxsDGlepo';
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
          TextPart("""extract the text in this image. this is a receipt, 
          so ensure the extracted text is logical. don't include any text 
          that isn't in the uploaded image."""),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      setState(() {
        _textController.text = response.text ?? 'No text extracted.';
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
      appBar: AppBar(title: const Text("Gemini Image Processor")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    labelText: "Extracted Text",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
