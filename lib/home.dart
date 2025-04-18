import 'package:ai_recipe_generation/analyze.dart';
import 'package:ai_recipe_generation/eco-scan.dart';
import 'package:ai_recipe_generation/your_fridge.dart';
import 'package:ai_recipe_generation/navigation/bottom_nav.dart';
import 'package:ai_recipe_generation/recipe.dart';
import 'package:ai_recipe_generation/recipes_list.dart';
import 'package:ai_recipe_generation/scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final int initialTab;

  const HomePage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final user = FirebaseAuth.instance.currentUser!;

  String? extractedIngredients;
  List<String>? generatedRecipes;
  String? chosenRecipe;

  late int _selectedIndex;

  final List<IconData> _icons = [
    Icons.shopping_cart,
    Icons.emoji_food_beverage_outlined,
  ];

  final List<String> _labels = [
    'fridge',
    'scan',
  ];

  List<Widget> get _pages => [
    GenerateRecipes(
      onRecipesGenerated: (recipes) {
        setState(() {
          generatedRecipes = recipes.whereType<String>().toList();
        });
      },
    ),
    SustainabilityScanner(
      onExtracted: (ingredients) {
        setState(() {
          extractedIngredients = ingredients;
        });
      },
    ),
    GeminiImageProcessor(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    print("Initial tab: ${widget.initialTab}");
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      extractedIngredients = null;
      generatedRecipes = null;
      chosenRecipe = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;

    if (extractedIngredients != null) {
      print("Extracted: $extractedIngredients");
      currentPage = SustainabilityAnalysisPage(ingredients: extractedIngredients!);
    } else if (chosenRecipe != null) {
      currentPage = RecipePage(recipe: chosenRecipe!);
    } else if (generatedRecipes != null) {
      currentPage = RecipeListPage(
        recipes: generatedRecipes!,
        onRecipeChosen: (recipe) {
          setState(() {
            chosenRecipe = recipe;
          });
        },
      );
      if (chosenRecipe != null) {
        currentPage = RecipePage(recipe: chosenRecipe!);
      }
    } else {
      currentPage = _pages[_selectedIndex];
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
          child: Text(
            "e c o p l a t e",
            style: GoogleFonts.poppins(
              color: const Color(0xFFfefae0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF283618),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: IconButton(
              onPressed: signUserOut,
              icon: const Icon(Icons.logout_rounded),
              color: const Color(0xFFfefae0),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFf1faee),
      body: currentPage,
      bottomNavigationBar: BottomNavigation(
        onTabChange: navigateBottomBar,
        labels: _labels,
        numberOfTabs: _icons.length,
        icons: _icons,
      ),
    );
  }
}
