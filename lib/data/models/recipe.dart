import 'package:flutter/material.dart' show Color;

import 'enums.dart';

class NutritionInfo {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const NutritionInfo({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class RecipeStep {
  final int order;
  final String text;
  final int? minutes; // optional timer per step

  const RecipeStep({required this.order, required this.text, this.minutes});
}

class Substitution {
  final String missing;
  final String swap;
  final String reason;

  const Substitution({
    required this.missing,
    required this.swap,
    required this.reason,
  });
}

class Recipe {
  final String id;
  final String title;
  final String tagline;
  final String emoji;

  /// Optional CDN URL for a real food photo. When set, RecipeCard renders the
  /// image as the hero; otherwise it falls back to the emoji + gradient look.
  final String photoUrl;

  final List<Color> gradientColors;
  final RecipeCategory category;
  final DifficultyLevel difficulty;
  final int cookMinutes;
  final int servings;
  final NutritionInfo nutrition;
  final List<String> requiredIngredientIds;
  final List<String> optionalIngredientIds;
  final List<RecipeStep> steps;
  final List<Substitution> substitutions;
  final List<Mood> matchingMoods;
  final List<CuisineType> cuisines;
  final List<DietaryPreference> dietaryFits;
  final String whyRecommended;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.tagline,
    required this.emoji,
    this.photoUrl = '',
    required this.gradientColors,
    required this.category,
    required this.difficulty,
    required this.cookMinutes,
    required this.servings,
    required this.nutrition,
    required this.requiredIngredientIds,
    required this.optionalIngredientIds,
    required this.steps,
    required this.substitutions,
    required this.matchingMoods,
    required this.cuisines,
    required this.dietaryFits,
    required this.whyRecommended,
    required this.tags,
  });
}
