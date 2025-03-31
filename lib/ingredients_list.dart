import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IngredientsPage extends StatefulWidget {
  @override
  _IngredientsPageState createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  User? user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getUserIngredients() {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('ingredients')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Ingredients")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserIngredients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No ingredients found."));
          }
          final docs = snapshot.data!.docs;
          List<String> allIngredients = [];

          for (var doc in docs) {
            final ingredients = List<String>.from(doc['ingredients']);
            allIngredients.addAll(ingredients);
          }

          return ListView.builder(
            itemCount: allIngredients.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(allIngredients[index]),
              );
            },
          );
        },
      ),
    );
  }
}
