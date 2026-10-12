import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/recipe.dart';
import 'package:fridgenie/data/services/ai_service.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/providers/recipe_provider.dart';
import 'package:fridgenie/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;

  RecipeProvider newProvider() => RecipeProvider(
        aiService: AIService(),
        userProvider: UserProvider(store),
        store: store,
      );

  Recipe aiRecipe(int n, {String? title}) => Recipe.fromJson(
        MockRecipes.all.first.toJson()
          ..['id'] = 'gen_$n'
          ..['title'] = title ?? 'AI Recipe $n',
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
  });

  test('favorites survive a restart as full recipes', () {
    newProvider().toggleFavorite(aiRecipe(1));

    final restarted = newProvider();
    expect(restarted.isFavorite('gen_1'), isTrue);
    expect(restarted.recipeByIdOrNull('gen_1')?.title, 'AI Recipe 1');
  });

  test('a favorite AI recipe outlives the 50-recipe generated cap', () {
    final provider = newProvider();
    final favorite = aiRecipe(0);
    provider
      ..addGeneratedRecipe(favorite)
      ..toggleFavorite(favorite);
    for (var i = 1; i <= 60; i++) {
      provider.addGeneratedRecipe(aiRecipe(i));
    }

    final restarted = newProvider();
    expect(restarted.generatedRecipes, hasLength(50));
    expect(restarted.generatedById('gen_0'), isNull);
    expect(restarted.isFavorite('gen_0'), isTrue);
    expect(restarted.recipeByIdOrNull('gen_0'), isNotNull);
  });

  test('toggling twice removes the favorite', () {
    final provider = newProvider();
    final recipe = MockRecipes.all.first;
    provider
      ..toggleFavorite(recipe)
      ..toggleFavorite(recipe);
    expect(newProvider().favorites, isEmpty);
  });

  test('duplicate titles are detected across different ids', () {
    final provider = newProvider()..toggleFavorite(aiRecipe(1, title: 'Soup'));
    expect(provider.isTitleAlreadySaved('gen_2', ' soup '), isTrue);
    expect(provider.isTitleAlreadySaved('gen_1', 'Soup'), isFalse);
  });

  test('liking a swipe card favorites it once, skipping duplicate titles', () {
    final provider = newProvider()
      ..toggleFavorite(aiRecipe(1, title: 'Soup'))
      ..seedSwipeDeck([aiRecipe(2, title: 'Soup'), aiRecipe(3)]);

    provider
      ..swipe(liked: true)
      ..swipe(liked: true);

    expect(provider.favorites, {'gen_1', 'gen_3'});
    expect(provider.liked, {'gen_2', 'gen_3'});
  });
}
