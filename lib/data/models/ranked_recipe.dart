import 'recipe.dart';

/// A recipe plus how well it matches the user's fridge.
class RankedRecipe {
  final Recipe recipe;

  /// Share of required ingredients the user has, from 0 to 1.
  final double matchScore;
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

  /// Builds a ranking from ingredient coverage against [availableIds].
  factory RankedRecipe.fromCoverage(
    Recipe recipe,
    Iterable<String> availableIds, {
    String? reason,
  }) {
    final available = availableIds.toSet();
    final required = recipe.requiredIngredientIds;
    final have = required.where(available.contains).toList();
    final missing = required.where((id) => !available.contains(id)).toList();
    return RankedRecipe(
      recipe: recipe,
      matchScore: required.isEmpty ? 0 : have.length / required.length,
      haveIngredients: have,
      missingIngredients: missing,
      aiReason: reason ?? recipe.whyRecommended,
    );
  }

  int get matchPercent => (matchScore * 100).round();
}
