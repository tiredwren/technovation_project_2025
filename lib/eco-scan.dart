import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SustainabilityScanner extends StatefulWidget {
  final void Function(String, String) onExtracted;

  const SustainabilityScanner({Key? key, required this.onExtracted}) : super(key: key);

  @override
  _SustainabilityScannerState createState() => _SustainabilityScannerState();
}

class _SustainabilityScannerState extends State<SustainabilityScanner> {
  final String apiKey = 'API_KEY';
  late final GenerativeModel _model;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
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
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _companyController.dispose();
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
          TextPart("""Extract the text in this image. This is a list of product ingredients. 
After extracting the text, please identify any company name or website URL within the text, 
and include it as part of the extracted information. Ensure accuracy and logic in the extraction."""),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      String extractedText = response.text ?? 'no text extracted.';

      // clean the extracted text before further processing for consistency
      extractedText = _cleanText(extractedText);

      // making sure AI looks at company/source
      String companyOrWebsite = await _extractCompanyFromAI(extractedText);
      setState(() {
        _textController.text = extractedText;
        _companyController.text = companyOrWebsite;
        extracting = false;
      });
    } catch (e) {
      setState(() {
        _textController.text = 'error processing image: $e';
        extracting = false;
      });
    }
  }

  Future<String> _extractCompanyFromAI(String text) async {
    try {
      final content = [
        Content.multi([
          TextPart("""Extract the company name or website URL from the following text: $text
          Please provide the name of the company or the URL if it is present. If neither is found, return 'not found in the image. please enter it to the best of your knowledge!'."""),
        ])
      ];

      final response = await _model.generateContent(content);
      String companyOrWebsite = response.text ?? 'none';
      return companyOrWebsite;
    } catch (e) {
      return 'error extracting company/website: $e';
    }
  }

  // ensure extracted text is properly formatted
  String _cleanText(String text) {
    text = text.replaceAll(RegExp(r'[*]'), '');
    text = text.replaceAll(RegExp(r'[^\w\s,.:;]'), '');
    text = text.toLowerCase().trim();
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
        "s c a n   f o r   s u s t a i n a b i l i t y",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: const Color(0xFF283618),
        ),
      ),
        centerTitle: true,),
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
              TextField(
                controller: _companyController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: extracting
                      ? "processing image..."
                      : "company name or website (edit as necessary)",
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
                    widget.onExtracted(_textController.text, _companyController.text);
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
