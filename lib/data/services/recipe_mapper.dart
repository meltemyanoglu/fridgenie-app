import 'dart:math';

import 'package:flutter/material.dart' show Color;

import '../models/enums.dart';
import '../models/recipe.dart';
import 'ingredient_matcher.dart';

/// Turns one recipe from the Worker's JSON into a [Recipe].
/// The Worker already sanitizes values; this layer stays lenient anyway.
class RecipeMapper {
  RecipeMapper({IngredientMatcher? matcher, Random? random})
      : _matcher = matcher ?? IngredientMatcher(),
        _random = random ?? Random();

  final IngredientMatcher _matcher;
  final Random _random;

  Recipe fromJson(Map<String, dynamic> json) {
    final title = _string(json['title'], 'Genie Original');
    final category = _enum(json['category'], RecipeCategory.values) ??
        RecipeCategory.comfort;
    final required = _matcher.matchAll(_strings(json['ingredients']));
    final optional = _matcher.matchAll(_strings(json['optionalIngredients']));

    return Recipe(
      id: 'gen_${DateTime.now().microsecondsSinceEpoch}_'
          '${_random.nextInt(0x7fffffff)}',
      title: title,
      tagline: _string(json['tagline'], ''),
      emoji: _string(json['emoji'], '🍽️'),
      photoUrl: _photoFor(category),
      gradientColors: gradientFor(category),
      category: category,
      difficulty: _enum(json['difficulty'], DifficultyLevel.values) ??
          DifficultyLevel.easy,
      cookMinutes: _int(json['cookMinutes'], 25),
      servings: _int(json['servings'], 2),
      nutrition: _nutrition(json['nutrition']),
      requiredIngredientIds: required.matched.map((i) => i.id).toList(),
      optionalIngredientIds: optional.matched
          .map((i) => i.id)
          .where((id) => !required.matched.any((r) => r.id == id))
          .toList(),
      extraIngredientNames: required.unmatched,
      steps: _steps(json['steps']),
      substitutions: _substitutions(json['substitutions']),
      matchingMoods: _enumList(json['moods'], Mood.values).ifEmpty(Mood.cozy),
      cuisines: _enumList(json['cuisines'], CuisineType.values),
      dietaryFits: _enumList(json['dietary'], DietaryPreference.values),
      whyRecommended: _string(
        json['whyRecommended'],
        'Genie invented this one for what you have.',
      ),
      tags: _strings(json['tags']).ifEmpty('ai-generated'),
    );
  }

  /// Card gradient per category; shared so every recipe looks consistent.
  static List<Color> gradientFor(RecipeCategory category) =>
      switch (category) {
        RecipeCategory.comfort => const [Color(0xFFFFE7B8), Color(0xFFFFB088)],
        RecipeCategory.healthy => const [Color(0xFF8AD49C), Color(0xFF3DA35D)],
        RecipeCategory.quick => const [Color(0xFFFFD23F), Color(0xFFFFA630)],
        RecipeCategory.budget => const [Color(0xFFFFD23F), Color(0xFF8AD49C)],
        RecipeCategory.useItUp => const [Color(0xFFE5854A), Color(0xFFFF6B6B)],
      };

  static const Map<RecipeCategory, List<String>> _photoIds = {
    RecipeCategory.comfort: [
      'photo-1473093226795-af9932fe5856',
      'photo-1547592166-23ac45744acd',
      'photo-1532550907401-a500c9a57435',
      'photo-1543339494-b4cd4f7ba686',
      'photo-1476124369491-e7addf5db371',
    ],
    RecipeCategory.healthy: [
      'photo-1512621776951-a57141f2eefd',
      'photo-1490645935967-10de6ba17061',
      'photo-1540914124281-342587941389',
      'photo-1526470498-9ae73c665de8',
      'photo-1512916194211-3f2b7f5f7f1a',
    ],
    RecipeCategory.quick: [
      'photo-1565557623262-b51c2513a641',
      'photo-1612874742237-6526221588e3',
      'photo-1525351484163-7529414344d8',
      'photo-1553909489-cd47e0907980',
      'photo-1628294896516-04e5ce6938d0',
    ],
    RecipeCategory.budget: [
      'photo-1546069901-ba9599a7e63c',
      'photo-1604908176997-125f25cc6f3d',
      'photo-1505253758473-96b7015fcd40',
      'photo-1569718212165-3a8278d5f624',
      'photo-1598866594230-a7c12756260f',
    ],
    RecipeCategory.useItUp: [
      'photo-1541519227354-08fa5d50c44d',
      'photo-1604152135912-04a022e23696',
      'photo-1626700051175-6818013e1d4f',
      'photo-1559847844-5315695dadae',
      'photo-1484980972926-edee96e0960d',
    ],
  };

  /// Stock photo for the category, so AI recipes get a hero image.
  String _photoFor(RecipeCategory category) {
    final ids = _photoIds[category]!;
    final id = ids[_random.nextInt(ids.length)];
    return 'https://images.unsplash.com/$id?w=800&auto=format&fit=crop';
  }

  static NutritionInfo _nutrition(Object? raw) {
    final map = raw is Map ? raw : const {};
    return NutritionInfo(
      calories: _int(map['calories'], 0),
      proteinG: _int(map['proteinG'], 0),
      carbsG: _int(map['carbsG'], 0),
      fatG: _int(map['fatG'], 0),
    );
  }

  static List<RecipeStep> _steps(Object? raw) {
    final steps = <RecipeStep>[];
    if (raw is! List) return steps;
    for (final item in raw) {
      if (item is! Map) continue;
      final text = _string(item['text'], '');
      if (text.isEmpty) continue;
      final minutes = item['minutes'];
      steps.add(RecipeStep(
        order: steps.length + 1,
        text: text,
        minutes: minutes is num && minutes > 0 ? minutes.round() : null,
      ));
    }
    return steps;
  }

  static List<Substitution> _substitutions(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((s) => Substitution(
              missing: _string(s['missing'], ''),
              swap: _string(s['swap'], ''),
              reason: _string(s['reason'], ''),
            ))
        .where((s) => s.missing.isNotEmpty && s.swap.isNotEmpty)
        .toList();
  }

  static T? _enum<T extends Enum>(Object? raw, List<T> values) {
    if (raw is! String) return null;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  static List<T> _enumList<T extends Enum>(Object? raw, List<T> values) =>
      _strings(raw)
          .map((name) => _enum(name, values))
          .whereType<T>()
          .toSet()
          .toList();

  static List<String> _strings(Object? raw) => raw is List
      ? raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
      : <String>[];

  static String _string(Object? raw, String fallback) =>
      raw is String && raw.trim().isNotEmpty ? raw.trim() : fallback;

  static int _int(Object? raw, int fallback) =>
      raw is num && raw.isFinite ? raw.round() : fallback;
}

extension<T> on List<T> {
  /// Returns this list, or a single-item list with [fallback] when empty.
  List<T> ifEmpty(T fallback) => isEmpty ? [fallback] : this;
}
