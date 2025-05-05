import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportIssuePage extends StatefulWidget {
  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // close the keyboard when submit is pressed
      FocusScope.of(context).unfocus();

      // simulate a delay to mock backend action
      await Future.delayed(Duration(seconds: 2));

      print('the problem: ${_titleController.text}');
      print('description: ${_descriptionController.text}');
      print('email (optional): ${_emailController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('thanks for letting us know the issue! we will work on improving the system with your feedback!')),
      );

      // clear the form fields
      _titleController.clear();
      _descriptionController.clear();
      _emailController.clear();
    }
  }

  void _cancelForm() {
    // clear the form fields and go back to the previous screen
    _titleController.clear();
    _descriptionController.clear();
    _emailController.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "r e p o r t   a n   i s s u e",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF283618),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'what is the issue?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please give your issue a name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please describe the issue';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('submit'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cancelForm,
                        child: Text('cancel'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFDDA15E)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
