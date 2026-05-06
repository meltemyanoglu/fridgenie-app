import 'dart:math';

import '../mock/mock_ingredients.dart';
import '../mock/mock_recipes.dart';
import '../mock/mock_tips.dart';
import '../models/enums.dart';
import '../models/genie_tip.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';

/// Result wrapper for ranked recipe suggestions.
class RankedRecipe {
  final Recipe recipe;
  final double matchScore; // 0..1
  final List<String> haveIngredients;
  final List<String> missingIngredients;
  final String aiReason;

  const RankedRecipe({
    required this.recipe,
    required this.matchScore,
    required this.haveIngredients,
    required this.missingIngredients,
    required this.aiReason,
  });

  int get matchPercent => (matchScore * 100).round();
}

/// Simulated grocery suggestion with reasoning.
class GrocerySuggestion {
  final Ingredient ingredient;
  final String reason;
  const GrocerySuggestion({required this.ingredient, required this.reason});
}

/// Mock AI service. Real OpenAI/Anthropic calls would slot in here without
/// changing the rest of the app. Every method returns Future<T> with a small
/// artificial delay so the UI can show its delightful loading states.
class AIService {
  final Random _rng;
  AIService({Random? rng}) : _rng = rng ?? Random();

  Duration get _thinkDelay => const Duration(milliseconds: 700);

  /// Suggest recipes based on what's in the fridge + user profile.
  Future<List<RankedRecipe>> suggestRecipes({
    required Set<String> ingredientIds,
    required UserProfile profile,
    Mood? mood,
    RecipeCategory? category,
  }) async {
    await Future.delayed(_thinkDelay);

    final scored = <RankedRecipe>[];

    for (final recipe in MockRecipes.all) {
      // Filter by category if requested
      if (category != null && recipe.category != category) continue;

      // Filter by mood if requested
      if (mood != null && !recipe.matchingMoods.contains(mood)) continue;

      // Dietary fit must overlap with user prefs (or no prefs)
      if (!profile.dietary.contains(DietaryPreference.noRestrictions) &&
          profile.dietary.isNotEmpty &&
          !recipe.dietaryFits.any(profile.dietary.contains)) {
        // Allow when user has prefs but recipe matches some — already checked.
        // If absolutely no overlap, skip.
        continue;
      }

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

  /// "Surprise Me Chef" — random recipe with a flair.
  Future<RankedRecipe> surpriseMe({required UserProfile profile}) async {
    await Future.delayed(_thinkDelay);
    final pool = MockRecipes.all;
    final recipe = pool[_rng.nextInt(pool.length)];
    return RankedRecipe(
      recipe: recipe,
      matchScore: 1.0,
      haveIngredients: recipe.requiredIngredientIds,
      missingIngredients: const [],
      aiReason: 'Genie rolled the dice and picked something ${recipe.matchingMoods.first.label.toLowerCase()}.',
    );
  }

  /// Fridge Challenge: suggest a recipe that uses ONLY the chosen 3 ingredients.
  Future<List<RankedRecipe>> challenge3Ingredients(List<String> ids) async {
    await Future.delayed(_thinkDelay);
    final results = <RankedRecipe>[];
    for (final r in MockRecipes.all) {
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

  // Photo scanning has moved to `IngredientRecognizer` (mock + real OpenAI
  // Vision implementations) — see `lib/data/services/ingredient_recognizer.dart`.

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
