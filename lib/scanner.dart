import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';  // For text recognition
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart'; // For OCR using Tesseract (alternative/backup)

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Scanner',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ReceiptScannerScreen(),
    );
  }
}

class ReceiptScannerScreen extends StatefulWidget {
  @override
  _ReceiptScannerScreenState createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  File? _image;
  String _extractedText = 'No text extracted yet.';
  List<String> _products = [];
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _extractedText = 'Extracting text...';  // Reset and indicate loading
        _products = [];
        _isLoading = true;
        _extractTextFromImage();
      } else {
        print('No image selected.');
      }
    });
  }


  // Using Google ML Kit for OCR (preferred)
  Future<void> _extractTextFromImage() async {
    if (_image == null) return;

    final inputImage = InputImage.fromFile(_image!);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _extractedText = recognizedText.text;
        _products = _extractProducts(_extractedText);
      });

    } catch (e) {
      print("Error using Google ML Kit: $e");
      // Fallback to Tesseract if ML Kit fails
      _extractTextFromImageTesseract(); // Call Tesseract OCR
    } finally {
      await textRecognizer.close();
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Using Tesseract OCR as a fallback
  Future<void> _extractTextFromImageTesseract() async {
    if (_image == null) return;

    try {
      String tessResult = await FlutterTesseractOcr.extractText(_image!.path);
      setState(() {
        _extractedText = tessResult;
        _products = _extractProducts(_extractedText);
      });
    } catch (e) {
      print("Error using Tesseract OCR: $e");
      setState(() {
        _extractedText = "Error extracting text. Please try another image or ensure text is clear.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Basic product extraction logic (improve this!)
  List<String> _extractProducts(String text) {
    List<String> products = [];
    // This is a VERY basic implementation.  You'll need to improve it!
    // Look for lines that are likely to be product names (e.g., not "TOTAL", "SUBTOTAL", etc.)
    // Use regular expressions or other techniques to refine this.
    for (String line in text.split('\n')) {
      line = line.trim();
      if (line.isNotEmpty &&
          !line.startsWith('TOTAL') &&
          !line.startsWith('SUBTOTAL') &&
          !line.startsWith('TAX') &&
          !line.contains(':') &&
          !line.contains(RegExp(r'[0-9]')) // Avoid lines with numbers (price).  Be careful about product names with numbers.
      ) {
        products.add(line);
      }
    }
    return products;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text('Take a Photo'),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Choose from Gallery'),
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.file(
                  _image!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Extracted Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_extractedText),
                  const SizedBox(height: 16),
                  const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_products.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _products.map((product) => Text('- $product')).toList(),
                    )
                  else
                    const Text('No products found.'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}