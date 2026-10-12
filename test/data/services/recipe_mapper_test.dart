import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/services/recipe_mapper.dart';

void main() {
  final mapper = RecipeMapper(random: Random(1));

  Map<String, dynamic> workerRecipe() => {
        'title': 'Tomato Egg Skillet',
        'tagline': 'Weeknight hero',
        'emoji': '🍳',
        'category': 'quick',
        'difficulty': 'medium',
        'cookMinutes': 15,
        'servings': 2,
        'nutrition': {'calories': 320, 'proteinG': 18, 'carbsG': 12, 'fatG': 20},
        'ingredients': ['tomatoes', 'eggs', 'saffron'],
        'optionalIngredients': ['basil', 'eggs'],
        'steps': [
          {'order': 1, 'text': 'Chop.', 'minutes': 3},
          {'order': 2, 'text': 'Cook.'},
        ],
        'substitutions': [
          {'missing': 'basil', 'swap': 'parsley', 'reason': 'Fresh'},
        ],
        'moods': ['cozy', 'energetic'],
        'cuisines': ['turkish'],
        'dietary': ['vegetarian'],
        'whyRecommended': 'Uses what you have.',
        'tags': ['quick'],
      };

  test('maps a full Worker recipe', () {
    final recipe = mapper.fromJson(workerRecipe());

    expect(recipe.id, startsWith('gen_'));
    expect(recipe.title, 'Tomato Egg Skillet');
    expect(recipe.category, RecipeCategory.quick);
    expect(recipe.difficulty, DifficultyLevel.medium);
    expect(recipe.nutrition.calories, 320);
    expect(recipe.requiredIngredientIds, ['tomato', 'eggs']);
    expect(recipe.optionalIngredientIds, ['basil']);
    expect(recipe.extraIngredientNames, ['saffron']);
    expect(recipe.steps.map((s) => s.order), [1, 2]);
    expect(recipe.steps.first.minutes, 3);
    expect(recipe.steps.last.minutes, isNull);
    expect(recipe.matchingMoods, [Mood.cozy, Mood.energetic]);
    expect(recipe.cuisines, [CuisineType.turkish]);
    expect(recipe.dietaryFits, [DietaryPreference.vegetarian]);
    expect(recipe.gradientColors, hasLength(2));
    expect(recipe.photoUrl, startsWith('https://images.unsplash.com/'));
  });

  test('falls back safely on missing or invalid fields', () {
    final recipe = mapper.fromJson({
      'category': 'dessert',
      'cookMinutes': 'soon',
      'moods': ['grumpy'],
      'steps': [
        {'text': '   '},
        'nonsense',
        {'text': 'Eat.', 'minutes': 0},
      ],
    });

    expect(recipe.title, 'Genie Original');
    expect(recipe.emoji, '🍽️');
    expect(recipe.category, RecipeCategory.comfort);
    expect(recipe.cookMinutes, 25);
    expect(recipe.matchingMoods, [Mood.cozy]);
    expect(recipe.tags, ['ai-generated']);
    expect(recipe.steps.single.order, 1);
    expect(recipe.steps.single.minutes, isNull);
    expect(recipe.nutrition.calories, 0);
  });

  test('gives every recipe a unique id', () {
    final ids = List.generate(20, (_) => mapper.fromJson(workerRecipe()).id);
    expect(ids.toSet(), hasLength(20));
  });
}
