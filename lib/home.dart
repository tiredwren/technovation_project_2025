import 'package:ai_recipe_generation/eco-scan.dart';
import 'package:ai_recipe_generation/generate_recipes.dart';
import 'package:ai_recipe_generation/navigation/bottom_nav.dart';
import 'package:ai_recipe_generation/recipe.dart';
import 'package:ai_recipe_generation/signup_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final user = FirebaseAuth.instance.currentUser!;

  // for nav bar
  int _selectedIndex = 0;

  // Define icons for tabs
  final List<IconData> _icons = [
    Icons.shopping_cart,
    Icons.emoji_food_beverage_outlined,
  ];

  // Define labels for tabs
  final List<String> _labels = [
    'Shop',
    'Saved',
  ];

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // pages
  final List<Widget> _pages = [
    GenerateRecipes(),
    SustainabilityScanner(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Text("App Name", style: TextStyle(color: Color(0xFFfefae0)),),
        ),
        backgroundColor: Color(0xFF283618),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: IconButton(
              onPressed: signUserOut,
              icon: Icon(Icons.logout_rounded),
              color: Color(0xFFfefae0),
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFFfefae0),
      body: _pages[_selectedIndex], // display the selected page
      bottomNavigationBar: BottomNavigation(
        onTabChange: navigateBottomBar,
        labels: _labels,
        numberOfTabs: _icons.length,
        icons: _icons, // pass icons to the bottom navigation bar
      ),
    );
  }
}