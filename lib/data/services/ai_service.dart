import 'dart:math';

import 'package:flutter/foundation.dart';

import '../mock/mock_ingredients.dart';
import '../mock/mock_recipes.dart';
import '../mock/mock_tips.dart';
import '../models/enums.dart';
import '../models/genie_tip.dart';
import '../models/ingredient.dart';
import '../models/ranked_recipe.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';

export '../models/ranked_recipe.dart';

/// Simulated grocery suggestion with reasoning.
class GrocerySuggestion {
  final Ingredient ingredient;
  final String reason;
  const GrocerySuggestion({required this.ingredient, required this.reason});
}

/// Offline recipe brain built on the mock catalog.
/// Real AI calls live in FridgenieApi.
/// Methods add a short delay so the UI can show its loading states.
class AIService {
  AIService({
    Random? rng,
    Duration thinkDelay = const Duration(milliseconds: 700),
  })  : _rng = rng ?? Random(),
        _thinkDelay = thinkDelay;

  final Random _rng;

  /// Fake "thinking" time so loading states are visible; zero in tests.
  final Duration _thinkDelay;

  /// Mock recipes the user is allowed to eat, by every dietary restriction.
  List<Recipe> _allowedFor(UserProfile profile) =>
      MockRecipes.all.where((r) => r.satisfiesDiet(profile.dietary)).toList();

  /// Suggest recipes based on what's in the fridge + user profile.
  Future<List<RankedRecipe>> suggestRecipes({
    required Set<String> ingredientIds,
    required UserProfile profile,
    Mood? mood,
    RecipeCategory? category,
  }) async {
    await Future.delayed(_thinkDelay);

    final scored = <RankedRecipe>[];

    for (final recipe in _allowedFor(profile)) {
      if (category != null && recipe.category != category) continue;
      if (mood != null && !recipe.matchingMoods.contains(mood)) continue;

      final required = recipe.requiredIngredientIds;
      final have = required.where(ingredientIds.contains).toList();
      final missing = required.where((id) => !ingredientIds.contains(id)).toList();

      if (required.isEmpty) continue;
      final ingredientCoverage = have.length / required.length;

      // Bonuses
      double cuisineBonus = recipe.cuisines.any(profile.favoriteCuisines.contains) ? 0.10 : 0;
      double moodBonus = recipe.matchingMoods.contains(profile.defaultMood) ? 0.05 : 0;
      double quickBonus = recipe.cookMinutes <= 20 ? 0.05 : 0;

      final score =
          (ingredientCoverage * 0.7 + cuisineBonus + moodBonus + quickBonus)
              .clamp(0.0, 1.0);

      // Threshold: at least 1 ingredient must overlap
      if (have.isEmpty && ingredientIds.isNotEmpty) continue;

      scored.add(RankedRecipe(
        recipe: recipe,
        matchScore: score,
        haveIngredients: have,
        missingIngredients: missing,
        aiReason: _buildReason(recipe, have, missing, profile),
      ));
    }

    scored.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scored;
  }

  /// "Surprise Me Chef": a random recipe the user's diet allows.
  Future<RankedRecipe> surpriseMe({
    required UserProfile profile,
    Set<String> ingredientIds = const {},
  }) async {
    await Future.delayed(_thinkDelay);
    var pool = _allowedFor(profile);
    if (pool.isEmpty) {
      debugPrint('[AIService] no mock recipe fits ${profile.dietary}; '
          'surprising from the full catalog');
      pool = MockRecipes.all;
    }
    final recipe = pool[_rng.nextInt(pool.length)];
    final mood = recipe.matchingMoods.firstOrNull?.label.toLowerCase();
    return RankedRecipe.fromCoverage(
      recipe,
      ingredientIds,
      reason: mood == null
          ? 'Genie rolled the dice for you.'
          : 'Genie rolled the dice and picked something $mood.',
    );
  }

  /// Best offline recipe for [mode]; used when the AI is missing or fails.
  Future<Recipe> fallbackRecipe({
    required Set<String> ingredientIds,
    required UserProfile profile,
    required GenieMode mode,
  }) async {
    if (mode == GenieMode.surpriseMe || ingredientIds.isEmpty) {
      return (await surpriseMe(profile: profile, ingredientIds: ingredientIds))
          .recipe;
    }

    final ranked = mode == GenieMode.leftoversRescue
        ? await rescueLeftovers(ingredientIds: ingredientIds, profile: profile)
        : await suggestRecipes(ingredientIds: ingredientIds, profile: profile);

    final candidates = mode == GenieMode.healthyQuick
        ? ranked.where((r) =>
            r.recipe.category == RecipeCategory.healthy ||
            r.recipe.cookMinutes <= 20)
        : ranked;

    if (candidates.isNotEmpty) return candidates.first.recipe;
    if (ranked.isNotEmpty) return ranked.first.recipe;
    return (await surpriseMe(profile: profile)).recipe;
  }

  /// Fridge Challenge: suggest a recipe that uses ONLY the chosen 3 ingredients.
  Future<List<RankedRecipe>> challenge3Ingredients(
    List<String> ids, {
    required UserProfile profile,
  }) async {
    await Future.delayed(_thinkDelay);
    final results = <RankedRecipe>[];
    for (final r in _allowedFor(profile)) {
      final overlap = r.requiredIngredientIds.where(ids.contains).length;
      if (r.requiredIngredientIds.length <= 4 && overlap >= 2) {
        results.add(RankedRecipe(
          recipe: r,
          matchScore: overlap / r.requiredIngredientIds.length,
          haveIngredients: r.requiredIngredientIds.where(ids.contains).toList(),
          missingIngredients: r.requiredIngredientIds.where((i) => !ids.contains(i)).toList(),
          aiReason: 'Built around the ${overlap == 3 ? "3 ingredients you picked" : "ingredients you locked in"}.',
        ));
      }
    }
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return results.take(5).toList();
  }

  /// Leftover Rescue: prioritise Use-It-Up category and forgiving recipes.
  Future<List<RankedRecipe>> rescueLeftovers({
    required Set<String> ingredientIds,
    required UserProfile profile,
  }) async {
    final all = await suggestRecipes(
      ingredientIds: ingredientIds,
      profile: profile,
    );
    // Boost Use-It-Up and "forgiving" tags
    return all.map((r) {
      final boost = r.recipe.category == RecipeCategory.useItUp ? 0.2 : 0.0;
      final tagBoost = r.recipe.tags.contains('forgiving') ? 0.1 : 0.0;
      final newScore = (r.matchScore + boost + tagBoost).clamp(0.0, 1.0);
      return RankedRecipe(
        recipe: r.recipe,
        matchScore: newScore,
        haveIngredients: r.haveIngredients,
        missingIngredients: r.missingIngredients,
        aiReason: 'Designed to save what you already have.',
      );
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  // Photo scanning lives in `IngredientRecognizer` (ingredient_recognizer.dart).

  /// Suggest grocery items to complete a recipe + reason.
  Future<List<GrocerySuggestion>> suggestGroceries({
    required Recipe recipe,
    required Set<String> ingredientIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final missing = recipe.requiredIngredientIds.where((id) => !ingredientIds.contains(id));
    return missing.map((id) {
      final ing = MockIngredients.byId(id);
      return GrocerySuggestion(
        ingredient: ing ?? const Ingredient(
          id: 'unknown', name: 'Unknown', emoji: '❓',
          category: IngredientCategory.pantry,
        ),
        reason: 'Required for "${recipe.title}".',
      );
    }).toList();
  }

  /// Daily Genie tip.
  GenieTip tipOfTheDay() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return MockTips.ofTheDay(dayOfYear);
  }

  /// Build a human-feeling reason string.
  String _buildReason(
    Recipe recipe,
    List<String> have,
    List<String> missing,
    UserProfile profile,
  ) {
    final parts = <String>[];
    if (have.isNotEmpty) {
      parts.add('You already have ${have.length}/${recipe.requiredIngredientIds.length} key ingredients');
    }
    if (recipe.cuisines.any(profile.favoriteCuisines.contains)) {
      final c = recipe.cuisines.firstWhere(profile.favoriteCuisines.contains);
      parts.add('matches your love of ${c.label}');
    }
    if (recipe.cookMinutes <= 20) {
      parts.add('cooks in under 20 minutes');
    }
    if (recipe.matchingMoods.contains(profile.defaultMood)) {
      parts.add('fits a ${profile.defaultMood.label.toLowerCase()} mood');
    }
    if (parts.isEmpty) {
      return recipe.whyRecommended;
    }
    return '${parts.join(' · ').capitalised}.';
  }
}

extension on String {
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
