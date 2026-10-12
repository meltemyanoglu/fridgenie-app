import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/models/recipe.dart';
import 'package:fridgenie/data/models/user_profile.dart';
import 'package:fridgenie/data/services/ai_service.dart';
import 'package:fridgenie/data/services/fridgenie_api.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/providers/recipe_provider.dart';
import 'package:fridgenie/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake backend: returns [recipe] or throws [error].
class _FakeApi implements FridgenieApi {
  _FakeApi({this.recipe, this.error});

  final Recipe? recipe;
  final FridgenieApiException? error;
  final requests = <RecipeRequest>[];

  @override
  Future<List<Recipe>> generateRecipes(RecipeRequest request) async {
    requests.add(request);
    if (error != null) throw error!;
    return [recipe!];
  }

  @override
  Future<List<String>> scanIngredients(Uint8List imageBytes) async => [];

  @override
  void close() {}
}

/// Offline brain whose suggestion calls finish only when the test says so.
class _ControlledAI extends AIService {
  _ControlledAI() : super(thinkDelay: Duration.zero);

  final pending = <Completer<List<RankedRecipe>>>[];
  bool failSurprise = false;

  @override
  Future<List<RankedRecipe>> suggestRecipes({
    required Set<String> ingredientIds,
    required UserProfile profile,
    Mood? mood,
    RecipeCategory? category,
  }) {
    final completer = Completer<List<RankedRecipe>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<RankedRecipe> surpriseMe({
    required UserProfile profile,
    Set<String> ingredientIds = const {},
  }) async {
    if (failSurprise) throw StateError('boom');
    return super.surpriseMe(profile: profile, ingredientIds: ingredientIds);
  }
}

void main() {
  late LocalStore store;
  late UserProvider user;

  final aiRecipe = Recipe.fromJson(MockRecipes.all.first.toJson()
    ..['id'] = 'gen_test'
    ..['title'] = 'Genie Test Dish');

  RecipeProvider newProvider({AIService? ai, FridgenieApi? api}) =>
      RecipeProvider(
        aiService: ai ?? AIService(thinkDelay: Duration.zero),
        userProvider: user,
        store: store,
        api: api,
      );

  RankedRecipe ranked(String id) =>
      RankedRecipe.fromCoverage(MockRecipes.byId(id), const []);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    user = UserProvider(store);
  });

  test('offline suggestions respect every dietary restriction', () async {
    user.setDietary({DietaryPreference.vegan, DietaryPreference.glutenFree});
    final provider = newProvider();

    await provider.generateSuggestions({'tomato', 'onion', 'rice', 'garlic'});

    expect(provider.suggestions, isNotEmpty);
    for (final s in provider.suggestions) {
      expect(s.recipe.satisfiesDiet(user.profile.dietary), isTrue,
          reason: s.recipe.title);
    }
  });

  test('a slow older suggestion request cannot overwrite a newer one', () async {
    final ai = _ControlledAI();
    final provider = newProvider(ai: ai);
    final older = MockRecipes.all[0].id;
    final newer = MockRecipes.all[1].id;

    final first = provider.generateSuggestions({'eggs'});
    final second = provider.generateSuggestions({'tomato'});
    ai.pending[1].complete([ranked(newer)]);
    await second;
    ai.pending[0].complete([ranked(older)]);
    await first;

    expect(provider.suggestions.single.recipe.id, newer);
    expect(provider.suggestionsState, RequestState.success);
  });

  test('a failing surprise ends in an error state, not a stuck spinner',
      () async {
    final provider = newProvider(ai: _ControlledAI()..failSurprise = true);
    await provider.rollSurprise();
    expect(provider.surpriseState, RequestState.error);
  });

  test('a real AI recipe is saved and counted for AI Pioneer', () async {
    final api = _FakeApi(recipe: aiRecipe);
    final provider = newProvider(api: api);

    final result = await provider.generateWithGemini(
      ingredientIds: ['eggs', 'bell_pepper'],
      mode: GenieMode.healthyQuick,
    );

    expect(result?.recipe.id, 'gen_test');
    expect(provider.lastGenerationUsedGemini, isTrue);
    expect(provider.geminiError, isNull);
    expect(provider.generatedRecipes.first.id, 'gen_test');
    expect(api.requests.single.ingredientNames, ['eggs', 'bell pepper']);
    expect(api.requests.single.mode, GenieMode.healthyQuick);
    final pioneer = user.badges.firstWhere((b) => b.id == 'ai_pioneer');
    expect(pioneer.progress, 10);
  });

  test('when the AI fails, a diet-safe offline recipe is shown with a reason',
      () async {
    user.setDietary({DietaryPreference.vegetarian});
    final provider = newProvider(
      api: _FakeApi(
        error: const FridgenieApiException(
          FridgenieErrorCode.rateLimited,
          'Too many requests.',
        ),
      ),
    );

    final result = await provider.generateWithGemini(ingredientIds: ['eggs']);

    expect(result, isNotNull);
    expect(result!.recipe.satisfiesDiet(user.profile.dietary), isTrue);
    expect(provider.lastGenerationUsedGemini, isFalse);
    expect(provider.geminiError, contains('Try again in a minute'));
    expect(provider.generatedRecipes, isEmpty);
  });

  test('cooking the current surprise counts for the Wildcard badge', () async {
    final provider = newProvider();
    await provider.rollSurprise();

    provider.markCooked(provider.surprise!.recipe);

    final wildcard = user.badges.firstWhere((b) => b.id == 'surprise_chef');
    expect(wildcard.progress, 33);
    expect(user.profile.recipesCooked, 1);
  });
}
