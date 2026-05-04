import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Recipe category — drives filters & coloring across the app.
enum RecipeCategory {
  comfort('Comfort Food', '🥘', AppColors.catComfort),
  healthy('Healthy Reset', '🥗', AppColors.catHealthy),
  quick('Quick 15-Min', '⚡️', AppColors.catQuick),
  budget('Budget Meals', '💸', AppColors.catBudget),
  useItUp('Use-It-Up', '♻️', AppColors.catUseItUp);

  const RecipeCategory(this.label, this.emoji, this.color);

  final String label;
  final String emoji;
  final Color color;
}

enum DifficultyLevel {
  easy('Easy', 1),
  medium('Medium', 2),
  hard('Hard', 3);

  const DifficultyLevel(this.label, this.value);
  final String label;
  final int value;
}

enum DietaryPreference {
  vegetarian('Vegetarian', '🥬'),
  vegan('Vegan', '🌱'),
  pescatarian('Pescatarian', '🐟'),
  glutenFree('Gluten-free', '🌾'),
  dairyFree('Dairy-free', '🥛'),
  keto('Keto', '🥑'),
  halal('Halal', '🕌'),
  kosher('Kosher', '✡️'),
  noRestrictions('No restrictions', '🍴');

  const DietaryPreference(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum CookingSkill {
  beginner('Just starting', '🐣', 'I follow recipes step-by-step'),
  comfortable('Comfortable', '👨‍🍳', 'I cook a few times a week'),
  confident('Confident', '🔥', 'I improvise & love trying new things'),
  pro('Pro at home', '⭐️', 'Friends ask for my recipes');

  const CookingSkill(this.label, this.emoji, this.tagline);
  final String label;
  final String emoji;
  final String tagline;
}

enum CuisineType {
  italian('Italian', '🍝'),
  mexican('Mexican', '🌮'),
  japanese('Japanese', '🍣'),
  indian('Indian', '🍛'),
  mediterranean('Mediterranean', '🫒'),
  middleEastern('Middle Eastern', '🥙'),
  turkish('Turkish', '🥘'),
  korean('Korean', '🍱'),
  thai('Thai', '🍜'),
  chinese('Chinese', '🥟'),
  french('French', '🥐'),
  american('American', '🍔');

  const CuisineType(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum Mood {
  cozy('Cozy', '🧸', AppColors.moodCozy, 'Something warm & homey'),
  energetic('Energetic', '⚡️', AppColors.moodEnergetic, 'Light, fresh, full of life'),
  calm('Calm', '🌿', AppColors.moodCalm, 'Mindful, simple, soothing'),
  celebratory('Celebratory', '🎉', AppColors.moodCelebratory, 'Treat yourself today'),
  adventurous('Adventurous', '🌶️', AppColors.moodAdventurous, 'Try something new'),
  comforted('Need Comfort', '🤍', AppColors.moodComfort, 'Hug-in-a-bowl food');

  const Mood(this.label, this.emoji, this.color, this.tagline);
  final String label;
  final String emoji;
  final Color color;
  final String tagline;
}

enum IngredientCategory {
  produce('Produce', '🥬'),
  protein('Protein', '🍗'),
  dairy('Dairy', '🧀'),
  grains('Grains', '🌾'),
  pantry('Pantry', '🥫'),
  herbs('Herbs & Spices', '🌿'),
  frozen('Frozen', '❄️'),
  condiments('Condiments', '🥫');

  const IngredientCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}
