import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analyze.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SustainabilityScanner extends StatefulWidget {
  final void Function(String) onExtracted;

  const SustainabilityScanner({Key? key, required this.onExtracted}) : super(key: key);

  @override
  _SustainabilityScannerState createState() => _SustainabilityScannerState();
}

class _SustainabilityScannerState extends State<SustainabilityScanner> {
  final String apiKey = 'AIzaSyATi56IvBnjGbZ5qhFOLtAPl7mf5owwrdI';
  late final GenerativeModel _model;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  bool extracting = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );

    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {

    });
}

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        extracting = true;
        _imageFile = File(pickedFile.path);
      });
      await _processImage(_imageFile!);
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
      String extractedText = response.text ?? 'no text extracted.';

      setState(() {
        _textController.text = extractedText;
        extracting = false;
      });
    } catch (e) {
      setState(() {
        _textController.text = 'error processing image: $e';
        extracting = false;
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: extracting
                      ? "processing image..."
                      : "ingredients list (edit as necessary)",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("upload ingredients list"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("take image of ingredients list"),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _textController.text != "" && !extracting
                      ? () {
                      print(_textController.text);
                      widget.onExtracted(_textController.text);
                    }
                  : null,
                  child: const Text("analyze sustainability"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}