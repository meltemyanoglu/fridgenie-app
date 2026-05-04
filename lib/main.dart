import 'package:flutter/material.dart';

void main() {
  runApp(const FridgenieApp());
}

class FridgenieApp extends StatelessWidget {
  const FridgenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridgenie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6ABF69),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Ingredient {
  final String name;
  final IconData icon;

  const Ingredient(this.name, this.icon);
}

class Recipe {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;

  const Recipe({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> selectedIngredients = [];

  final ingredients = const [
    Ingredient('Eggs', Icons.egg_alt),
    Ingredient('Tomato', Icons.local_pizza),
    Ingredient('Cheese', Icons.breakfast_dining),
    Ingredient('Rice', Icons.rice_bowl),
    Ingredient('Chicken', Icons.dinner_dining),
    Ingredient('Spinach', Icons.eco),
  ];

  final recipes = const [
    Recipe(
      title: 'Cheesy Tomato Omelette',
      subtitle: 'A quick protein-rich meal with simple ingredients.',
      time: '15 min',
      icon: Icons.egg_alt,
    ),
    Recipe(
      title: 'Green Rice Bowl',
      subtitle: 'A fresh bowl with rice, spinach and light seasoning.',
      time: '20 min',
      icon: Icons.rice_bowl,
    ),
    Recipe(
      title: 'Comfort Chicken Plate',
      subtitle: 'Easy dinner idea using fridge basics.',
      time: '25 min',
      icon: Icons.dinner_dining,
    ),
  ];

  void toggleIngredient(String name) {
    setState(() {
      if (selectedIngredients.contains(name)) {
        selectedIngredients.remove(name);
      } else {
        selectedIngredients.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fridgenie',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20382B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Turn ingredients into ideas.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A756D),
                ),
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3DF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.kitchen,
                      size: 38,
                      color: Color(0xFF3F7D44),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'What’s in your fridge today?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20382B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pick a few ingredients and discover simple meal ideas.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF5F6F62),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20382B),
                ),
              ),
              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ingredients.map((ingredient) {
                  final isSelected =
                      selectedIngredients.contains(ingredient.name);

                  return ChoiceChip(
                    selected: isSelected,
                    avatar: Icon(
                      ingredient.icon,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF3F7D44),
                    ),
                    label: Text(ingredient.name),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF20382B),
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: const Color(0xFF3F7D44),
                    backgroundColor: Colors.white,
                    onSelected: (_) => toggleIngredient(ingredient.name),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedIngredients.isEmpty ? null : () {},
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate meal ideas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20382B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD5D3CC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Suggested Recipes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20382B),
                ),
              ),
              const SizedBox(height: 14),

              ...recipes.map((recipe) => RecipeCard(recipe: recipe)),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7B8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              recipe.icon,
              color: const Color(0xFF9C6B1D),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20382B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recipe.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A756D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            recipe.time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3F7D44),
            ),
          ),
        ],
      ),
    );
  }
}