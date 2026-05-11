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

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> j) => NutritionInfo(
        calories: (j['calories'] as num).toInt(),
        proteinG: (j['proteinG'] as num).toInt(),
        carbsG: (j['carbsG'] as num).toInt(),
        fatG: (j['fatG'] as num).toInt(),
      );
}

class RecipeStep {
  final int order;
  final String text;
  final int? minutes;

  const RecipeStep({required this.order, required this.text, this.minutes});

  Map<String, dynamic> toJson() => {
        'order': order,
        'text': text,
        if (minutes != null) 'minutes': minutes,
      };

  factory RecipeStep.fromJson(Map<String, dynamic> j) => RecipeStep(
        order: (j['order'] as num).toInt(),
        text: j['text'] as String,
        minutes: j['minutes'] != null ? (j['minutes'] as num).toInt() : null,
      );
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

  Map<String, dynamic> toJson() => {
        'missing': missing,
        'swap': swap,
        'reason': reason,
      };

  factory Substitution.fromJson(Map<String, dynamic> j) => Substitution(
        missing: j['missing'] as String,
        swap: j['swap'] as String,
        reason: j['reason'] as String,
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tagline': tagline,
        'emoji': emoji,
        'photoUrl': photoUrl,
        'gradientColors': gradientColors.map((c) => c.toARGB32()).toList(),
        'category': category.name,
        'difficulty': difficulty.name,
        'cookMinutes': cookMinutes,
        'servings': servings,
        'nutrition': nutrition.toJson(),
        'requiredIngredientIds': requiredIngredientIds,
        'optionalIngredientIds': optionalIngredientIds,
        'steps': steps.map((s) => s.toJson()).toList(),
        'substitutions': substitutions.map((s) => s.toJson()).toList(),
        'matchingMoods': matchingMoods.map((m) => m.name).toList(),
        'cuisines': cuisines.map((c) => c.name).toList(),
        'dietaryFits': dietaryFits.map((d) => d.name).toList(),
        'whyRecommended': whyRecommended,
        'tags': tags,
      };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        title: j['title'] as String,
        tagline: (j['tagline'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🍽️',
        photoUrl: (j['photoUrl'] as String?) ?? '',
        gradientColors: ((j['gradientColors'] as List?) ?? [])
            .map((v) => Color(v as int))
            .toList(),
        category: RecipeCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => RecipeCategory.comfort,
        ),
        difficulty: DifficultyLevel.values.firstWhere(
          (e) => e.name == j['difficulty'],
          orElse: () => DifficultyLevel.easy,
        ),
        cookMinutes: (j['cookMinutes'] as num?)?.toInt() ?? 0,
        servings: (j['servings'] as num?)?.toInt() ?? 2,
        nutrition: j['nutrition'] != null
            ? NutritionInfo.fromJson(j['nutrition'] as Map<String, dynamic>)
            : const NutritionInfo(calories: 0, proteinG: 0, carbsG: 0, fatG: 0),
        requiredIngredientIds:
            List<String>.from((j['requiredIngredientIds'] as List?) ?? []),
        optionalIngredientIds:
            List<String>.from((j['optionalIngredientIds'] as List?) ?? []),
        steps: ((j['steps'] as List?) ?? [])
            .map((s) => RecipeStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        substitutions: ((j['substitutions'] as List?) ?? [])
            .map((s) => Substitution.fromJson(s as Map<String, dynamic>))
            .toList(),
        matchingMoods: ((j['matchingMoods'] as List?) ?? [])
            .map((m) => Mood.values.firstWhere(
                  (e) => e.name == m,
                  orElse: () => Mood.cozy,
                ))
            .toList(),
        cuisines: ((j['cuisines'] as List?) ?? [])
            .map((c) => CuisineType.values.firstWhere(
                  (e) => e.name == c,
                  orElse: () => CuisineType.italian,
                ))
            .toList(),
        dietaryFits: ((j['dietaryFits'] as List?) ?? [])
            .map((d) => DietaryPreference.values.firstWhere(
                  (e) => e.name == d,
                  orElse: () => DietaryPreference.noRestrictions,
                ))
            .toList(),
        whyRecommended: (j['whyRecommended'] as String?) ?? '',
        tags: List<String>.from((j['tags'] as List?) ?? []),
      );
}
