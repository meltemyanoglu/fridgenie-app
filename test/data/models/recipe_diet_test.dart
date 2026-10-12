import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/models/recipe.dart';

void main() {
  Recipe taggedWith(List<DietaryPreference> fits) => Recipe.fromJson(
        MockRecipes.all.first.toJson()
          ..['dietaryFits'] = fits.map((d) => d.name).toList(),
      );

  const vegan = DietaryPreference.vegan;
  const vegetarian = DietaryPreference.vegetarian;
  const pescatarian = DietaryPreference.pescatarian;
  const glutenFree = DietaryPreference.glutenFree;
  const dairyFree = DietaryPreference.dairyFree;

  test('every restriction must be met, not just one', () {
    final recipe = taggedWith([glutenFree]);
    expect(recipe.satisfiesDiet({vegan, glutenFree}), isFalse);
    expect(taggedWith([vegan, glutenFree]).satisfiesDiet({vegan, glutenFree}),
        isTrue);
  });

  test('vegan implies vegetarian, dairy-free and pescatarian', () {
    final recipe = taggedWith([vegan]);
    expect(recipe.satisfiesDiet({vegetarian, dairyFree, pescatarian}), isTrue);
  });

  test('vegetarian implies pescatarian, but not vegan', () {
    final recipe = taggedWith([vegetarian]);
    expect(recipe.satisfiesDiet({pescatarian}), isTrue);
    expect(recipe.satisfiesDiet({vegan}), isFalse);
  });

  test('no restrictions accepts anything', () {
    expect(taggedWith([]).satisfiesDiet({DietaryPreference.noRestrictions}),
        isTrue);
    expect(taggedWith([]).satisfiesDiet(const {}), isTrue);
  });
}
