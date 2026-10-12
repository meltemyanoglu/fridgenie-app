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

  static const empty =
      NutritionInfo(calories: 0, proteinG: 0, carbsG: 0, fatG: 0);

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  /// Lenient: missing or non-numeric values become 0.
  factory NutritionInfo.fromJson(Map<String, dynamic> j) => NutritionInfo(
        calories: _int(j['calories']) ?? 0,
        proteinG: _int(j['proteinG']) ?? 0,
        carbsG: _int(j['carbsG']) ?? 0,
        fatG: _int(j['fatG']) ?? 0,
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
        order: _int(j['order']) ?? 0,
        text: _string(j['text']) ?? '',
        minutes: _int(j['minutes']),
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
        missing: _string(j['missing']) ?? '',
        swap: _string(j['swap']) ?? '',
        reason: _string(j['reason']) ?? '',
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

  /// AI-listed ingredients that are not in the catalog, as plain names.
  final List<String> extraIngredientNames;
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
    this.extraIngredientNames = const [],
    required this.steps,
    required this.substitutions,
    required this.matchingMoods,
    required this.cuisines,
    required this.dietaryFits,
    required this.whyRecommended,
    required this.tags,
  });

  /// Card gradient per category, used whenever a recipe has no valid colors.
  static List<Color> gradientFor(RecipeCategory category) => switch (category) {
        RecipeCategory.comfort => const [Color(0xFFFFE7B8), Color(0xFFFFB088)],
        RecipeCategory.healthy => const [Color(0xFF8AD49C), Color(0xFF3DA35D)],
        RecipeCategory.quick => const [Color(0xFFFFD23F), Color(0xFFFFA630)],
        RecipeCategory.budget => const [Color(0xFFFFD23F), Color(0xFF8AD49C)],
        RecipeCategory.useItUp => const [Color(0xFFE5854A), Color(0xFFFF6B6B)],
      };

  /// True when the recipe meets **every** restriction in [prefs].
  bool satisfiesDiet(Iterable<DietaryPreference> prefs) => prefs.every(
      (pref) => pref == DietaryPreference.noRestrictions || _fits(pref));

  /// Vegan implies vegetarian and dairy-free; vegetarian implies pescatarian.
  bool _fits(DietaryPreference pref) {
    if (dietaryFits.contains(pref)) return true;
    final vegan = dietaryFits.contains(DietaryPreference.vegan);
    final vegetarian =
        vegan || dietaryFits.contains(DietaryPreference.vegetarian);
    return switch (pref) {
      DietaryPreference.vegetarian || DietaryPreference.dairyFree => vegan,
      DietaryPreference.pescatarian => vegetarian,
      _ => false,
    };
  }

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
        'extraIngredientNames': extraIngredientNames,
        'steps': steps.map((s) => s.toJson()).toList(),
        'substitutions': substitutions.map((s) => s.toJson()).toList(),
        'matchingMoods': matchingMoods.map((m) => m.name).toList(),
        'cuisines': cuisines.map((c) => c.name).toList(),
        'dietaryFits': dietaryFits.map((d) => d.name).toList(),
        'whyRecommended': whyRecommended,
        'tags': tags,
      };

  /// Lenient parser for stored recipes: unknown values get safe defaults.
  /// Throws [FormatException] only when `id` or `title` is missing.
  factory Recipe.fromJson(Map<String, dynamic> j) {
    final id = _string(j['id']);
    final title = _string(j['title']);
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      throw const FormatException('Recipe JSON needs an id and a title.');
    }

    final category =
        _enum(j['category'], RecipeCategory.values) ?? RecipeCategory.comfort;
    final colors = _list(j['gradientColors'])
        .whereType<int>()
        .map((value) => Color(value))
        .toList();
    final nutrition = j['nutrition'];

    return Recipe(
      id: id,
      title: title,
      tagline: _string(j['tagline']) ?? '',
      emoji: _string(j['emoji']) ?? '🍽️',
      photoUrl: _string(j['photoUrl']) ?? '',
      gradientColors: colors.length >= 2 ? colors : gradientFor(category),
      category: category,
      difficulty: _enum(j['difficulty'], DifficultyLevel.values) ??
          DifficultyLevel.easy,
      cookMinutes: _int(j['cookMinutes']) ?? 0,
      servings: _int(j['servings']) ?? 2,
      nutrition: nutrition is Map
          ? NutritionInfo.fromJson(Map<String, dynamic>.from(nutrition))
          : NutritionInfo.empty,
      requiredIngredientIds: _strings(j['requiredIngredientIds']),
      optionalIngredientIds: _strings(j['optionalIngredientIds']),
      extraIngredientNames: _strings(j['extraIngredientNames']),
      steps: _renumbered(_maps(j['steps'])
          .map(RecipeStep.fromJson)
          .where((s) => s.text.isNotEmpty)),
      substitutions: _maps(j['substitutions'])
          .map(Substitution.fromJson)
          .where((s) => s.missing.isNotEmpty && s.swap.isNotEmpty)
          .toList(),
      matchingMoods: _enums(j['matchingMoods'], Mood.values),
      cuisines: _enums(j['cuisines'], CuisineType.values),
      dietaryFits: _enums(j['dietaryFits'], DietaryPreference.values),
      whyRecommended: _string(j['whyRecommended']) ?? '',
      tags: _strings(j['tags']),
    );
  }
}

// ── Lenient JSON helpers shared by the models in this file ────────────────

int? _int(Object? value) =>
    value is num && value.isFinite ? value.round() : null;

String? _string(Object? value) => value is String ? value : null;

List<Object?> _list(Object? value) => value is List ? value : const [];

List<String> _strings(Object? value) =>
    _list(value).whereType<String>().toList();

List<Map<String, dynamic>> _maps(Object? value) => _list(value)
    .whereType<Map>()
    .map((m) => Map<String, dynamic>.from(m))
    .toList();

T? _enum<T extends Enum>(Object? value, List<T> values) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  return null;
}

/// Renumbers steps 1..n so a gap or a missing order never shows in the UI.
List<RecipeStep> _renumbered(Iterable<RecipeStep> steps) => [
      for (final (index, step) in steps.indexed)
        RecipeStep(order: index + 1, text: step.text, minutes: step.minutes),
    ];

List<T> _enums<T extends Enum>(Object? value, List<T> values) =>
    _list(value).map((v) => _enum(v, values)).whereType<T>().toList();
