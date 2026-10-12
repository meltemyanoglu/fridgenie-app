import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/models/grocery_item.dart';
import 'package:fridgenie/data/models/recipe.dart';

void main() {
  group('Recipe JSON', () {
    test('round-trips every mock recipe without loss', () {
      for (final recipe in MockRecipes.all) {
        final copy = Recipe.fromJson(recipe.toJson());
        expect(copy.toJson(), recipe.toJson(), reason: recipe.id);
      }
    });

    test('fills safe defaults for missing or broken fields', () {
      final recipe = Recipe.fromJson({
        'id': 'r1',
        'title': 'Soup',
        'category': 'healthy',
        'gradientColors': [123],
        'nutrition': 'lots',
        'cookMinutes': '20',
        'cuisines': ['italian', 'martian'],
        'steps': [
          {'order': 5, 'text': 'Boil.'},
          {'text': ''},
          {'order': 9, 'text': 'Serve.', 'minutes': 2},
        ],
        'substitutions': [
          {'missing': 'basil'},
        ],
      });

      expect(recipe.gradientColors, Recipe.gradientFor(RecipeCategory.healthy));
      expect(recipe.nutrition.calories, 0);
      expect(recipe.cookMinutes, 0);
      expect(recipe.cuisines, [CuisineType.italian]);
      expect(recipe.steps.map((s) => s.order), [1, 2]);
      expect(recipe.steps.last.minutes, 2);
      expect(recipe.substitutions, isEmpty);
      expect(recipe.emoji, '🍽️');
    });

    test('rejects a recipe without id or title', () {
      expect(() => Recipe.fromJson({'title': 'x'}), throwsFormatException);
      expect(() => Recipe.fromJson({'id': 'x', 'title': ''}),
          throwsFormatException);
    });
  });

  group('GroceryItem JSON', () {
    test('round-trips and defaults the emoji', () {
      const item = GroceryItem(id: 'g1', name: 'Milk', emoji: '🥛');
      expect(GroceryItem.fromJson(item.toJson()).toJson(), item.toJson());
      expect(GroceryItem.fromJson({'id': 'g2', 'name': 'Rice'}).emoji, '🛒');
    });

    test('rejects items without a name', () {
      expect(() => GroceryItem.fromJson({'id': 'g3'}), throwsFormatException);
    });
  });
}
