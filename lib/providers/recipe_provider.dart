import 'package:flutter/foundation.dart';

import '../data/mock/mock_ingredients.dart';
import '../data/mock/mock_recipes.dart';
import '../data/models/enums.dart';
import '../data/models/recipe.dart';
import '../data/services/ai_service.dart';
import '../data/services/fridgenie_api.dart';
import '../data/storage/local_store.dart';
import '../data/storage/storage_keys.dart';
import 'user_provider.dart';

enum RequestState { idle, loading, success, error }

class RecipeProvider extends ChangeNotifier {
  static const _tag = '[RecipeProvider]';

  final AIService _ai;
  final UserProvider _userProvider;
  final LocalStore _store;

  /// Null when the backend isn't configured; the app then runs in demo mode.
  final FridgenieApi? _api;

  RecipeProvider({
    required AIService aiService,
    required UserProvider userProvider,
    required LocalStore store,
    FridgenieApi? api,
  })  : _ai = aiService,
        _userProvider = userProvider,
        _store = store,
        _api = api {
    _generatedRecipes.addAll(store
        .readJsonList(StorageKeys.generatedRecipes, Recipe.fromJson)
        .take(_maxGenerated));
    for (final recipe
        in store.readJsonList(StorageKeys.favoriteRecipes, Recipe.fromJson)) {
      _favorites[recipe.id] = recipe;
    }
    debugPrint('$_tag loaded ${_generatedRecipes.length} generated, '
        '${_favorites.length} favorites');
  }

  /// True when real AI (Gemini via the Worker) is available.
  bool get geminiAvailable => _api != null;

  static const _genericError = 'Something went wrong. Please try again.';

  void _logFailure(String action, Object error, StackTrace stack) =>
      debugPrint('$_tag $action failed: $error\n$stack');

  // ── Suggestions (offline ranking) ───────────────────────────────────────
  List<RankedRecipe> _suggestions = [];
  RecipeCategory? _activeCategory;
  RequestState _suggestionsState = RequestState.idle;
  String? _suggestionsError;

  /// Bumped per request so a slow, older answer can't overwrite a newer one.
  int _suggestionsRequest = 0;

  List<RankedRecipe> get suggestions => _suggestions;
  RecipeCategory? get activeCategory => _activeCategory;
  RequestState get suggestionsState => _suggestionsState;
  String? get suggestionsError => _suggestionsError;

  void setActiveCategory(RecipeCategory? cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  Future<void> generateSuggestions(Set<String> ingredientIds) async {
    final request = ++_suggestionsRequest;
    _suggestionsState = RequestState.loading;
    _suggestionsError = null;
    notifyListeners();

    try {
      final results = await _ai.suggestRecipes(
        ingredientIds: ingredientIds,
        profile: _userProvider.profile,
        category: _activeCategory,
      );
      if (request != _suggestionsRequest) return;
      _suggestions = results;
      _suggestionsState = RequestState.success;
    } catch (e, stack) {
      if (request != _suggestionsRequest) return;
      _logFailure('generateSuggestions', e, stack);
      _suggestionsState = RequestState.error;
      _suggestionsError = _genericError;
    }
    notifyListeners();
  }

  // ── AI recipe generation (Gemini via the Worker) ────────────────────────
  RequestState _geminiState = RequestState.idle;
  String? _geminiError;
  bool _lastGenerationUsedGemini = false;

  RequestState get geminiState => _geminiState;
  String? get geminiError => _geminiError;
  bool get lastGenerationUsedGemini => _lastGenerationUsedGemini;

  /// Generates one AI recipe; on failure falls back to an offline recipe and
  /// explains why in [geminiError]. Returns null only on unexpected errors.
  Future<RankedRecipe?> generateWithGemini({
    required List<String> ingredientIds,
    GenieMode mode = GenieMode.standard,
  }) async {
    _geminiState = RequestState.loading;
    _geminiError = null;
    notifyListeners();

    try {
      final generation =
          await _generate(ingredientIds: ingredientIds, mode: mode);
      _lastGenerationUsedGemini = generation.fromAi;
      _geminiError = generation.fallbackReason;
      _geminiState = RequestState.success;
      notifyListeners();
      return RankedRecipe.fromCoverage(generation.recipe, ingredientIds);
    } catch (e, stack) {
      _logFailure('generateWithGemini', e, stack);
      _geminiState = RequestState.error;
      _geminiError = _genericError;
      notifyListeners();
      return null;
    }
  }

  /// Asks the AI for one recipe, or returns an offline recipe with a reason.
  /// Real AI recipes are saved and counted for the AI Pioneer badge.
  Future<_Generation> _generate({
    required List<String> ingredientIds,
    required GenieMode mode,
  }) async {
    final profile = _userProvider.profile;
    final api = _api;

    if (api == null) {
      return _Generation.fallback(
        await _fallbackRecipe(ingredientIds, mode),
        'Connect the Fridgenie backend to unlock real AI recipes.',
      );
    }

    try {
      final recipes = await api.generateRecipes(RecipeRequest(
        ingredientNames: ingredientIds.map(_ingredientName).toList(),
        mode: mode,
        dietary: profile.dietary,
        mood: profile.defaultMood,
        cuisine: profile.favoriteCuisines.isEmpty
            ? null
            : profile.favoriteCuisines.first,
        skill: profile.skill,
        avoidTitles: _generatedRecipes.map((r) => r.title).take(10).toList(),
      ));
      final recipe = recipes.first;
      debugPrint('$_tag AI recipe "${recipe.title}" ($mode)');
      addGeneratedRecipe(recipe);
      _userProvider.recordAiRecipeGenerated();
      return _Generation.ai(recipe);
    } on FridgenieApiException catch (e) {
      debugPrint('$_tag AI failed, using offline recipe: $e');
      return _Generation.fallback(
        await _fallbackRecipe(ingredientIds, mode),
        '${e.userMessage} Showing a demo recipe instead.',
      );
    }
  }

  Future<Recipe> _fallbackRecipe(List<String> ingredientIds, GenieMode mode) =>
      _ai.fallbackRecipe(
        ingredientIds: ingredientIds.toSet(),
        profile: _userProvider.profile,
        mode: mode,
      );

  static String _ingredientName(String id) =>
      (MockIngredients.byId(id)?.name ?? id.replaceAll('_', ' '))
          .toLowerCase();

  // ── Mood-based ──────────────────────────────────────────────────────────
  List<RankedRecipe> _moodSuggestions = [];
  Mood? _activeMood;
  RequestState _moodState = RequestState.idle;
  int _moodRequest = 0;

  List<RankedRecipe> get moodSuggestions => _moodSuggestions;
  Mood? get activeMood => _activeMood;
  RequestState get moodState => _moodState;

  Future<void> suggestForMood(Mood mood, Set<String> ingredientIds) async {
    final request = ++_moodRequest;
    _activeMood = mood;
    _moodState = RequestState.loading;
    notifyListeners();

    try {
      final results = await _ai.suggestRecipes(
        ingredientIds: ingredientIds,
        profile: _userProvider.profile,
        mood: mood,
      );
      if (request != _moodRequest) return;
      _moodSuggestions = results;
      _moodState = RequestState.success;
    } catch (e, stack) {
      if (request != _moodRequest) return;
      _logFailure('suggestForMood', e, stack);
      _moodState = RequestState.error;
    }
    notifyListeners();
  }

  // ── Surprise Me ─────────────────────────────────────────────────────────
  RankedRecipe? _surprise;
  RequestState _surpriseState = RequestState.idle;
  String? _surpriseFallbackReason;
  int _surpriseRequest = 0;

  RankedRecipe? get surprise => _surprise;
  RequestState get surpriseState => _surpriseState;

  /// Why the last surprise is a demo recipe instead of a real AI one.
  String? get surpriseFallbackReason => _surpriseFallbackReason;

  /// Rolls a surprise recipe; [ingredientIds] lets the AI use the fridge.
  Future<void> rollSurprise({Set<String> ingredientIds = const {}}) async {
    final request = ++_surpriseRequest;
    _surpriseState = RequestState.loading;
    notifyListeners();

    try {
      final RankedRecipe result;
      String? fallbackReason;
      if (_api != null) {
        final generation = await _generate(
          ingredientIds: ingredientIds.toList(),
          mode: GenieMode.surpriseMe,
        );
        result = RankedRecipe.fromCoverage(generation.recipe, ingredientIds);
        fallbackReason = generation.fallbackReason;
      } else {
        result = await _ai.surpriseMe(
          profile: _userProvider.profile,
          ingredientIds: ingredientIds,
        );
      }
      if (request != _surpriseRequest) return;
      _surprise = result;
      _surpriseFallbackReason = fallbackReason;
      _surpriseState = RequestState.success;
    } catch (e, stack) {
      if (request != _surpriseRequest) return;
      _logFailure('rollSurprise', e, stack);
      _surpriseState = RequestState.error;
    }
    notifyListeners();
  }

  // ── Challenge ───────────────────────────────────────────────────────────
  List<RankedRecipe> _challengeResults = [];
  RequestState _challengeState = RequestState.idle;

  List<RankedRecipe> get challengeResults => _challengeResults;
  RequestState get challengeState => _challengeState;

  Future<void> runChallenge(List<String> ids) async {
    _challengeState = RequestState.loading;
    notifyListeners();
    try {
      _challengeResults = await _ai.challenge3Ingredients(
        ids,
        profile: _userProvider.profile,
      );
      _challengeState = RequestState.success;
    } catch (e, stack) {
      _logFailure('runChallenge', e, stack);
      _challengeState = RequestState.error;
    }
    notifyListeners();
  }

  // ── Leftover Rescue ─────────────────────────────────────────────────────
  List<RankedRecipe> _rescueResults = [];
  RequestState _rescueState = RequestState.idle;

  List<RankedRecipe> get rescueResults => _rescueResults;
  RequestState get rescueState => _rescueState;

  Future<void> runRescue(Set<String> ids) async {
    _rescueState = RequestState.loading;
    notifyListeners();
    try {
      _rescueResults = await _ai.rescueLeftovers(
        ingredientIds: ids,
        profile: _userProvider.profile,
      );
      _rescueState = RequestState.success;
    } catch (e, stack) {
      _logFailure('runRescue', e, stack);
      _rescueState = RequestState.error;
    }
    notifyListeners();
  }

  // ── Cooking ─────────────────────────────────────────────────────────────

  /// Surprise/challenge recipes already counted, so re-cooking the same one
  /// can't farm the Wildcard or Minimalist badge.
  final Set<String> _countedSourceIds = {};

  /// Marks [recipe] as cooked; the result tells the UI about the streak and
  /// any new badges.
  CookResult markCooked(Recipe recipe) {
    final isSurprise = _surprise?.recipe.id == recipe.id;
    final isChallenge = _challengeResults.any((r) => r.recipe.id == recipe.id);
    final counts =
        (isSurprise || isChallenge) && _countedSourceIds.add(recipe.id);
    return _userProvider.recordCookedRecipe(
      recipe,
      fromSurprise: counts && isSurprise,
      fromChallenge: counts && isChallenge,
    );
  }

  // ── Favorites (full recipe snapshots, so they never disappear) ─────────
  /// Keyed by recipe id, in the order they were added.
  final Map<String, Recipe> _favorites = {};

  bool isFavorite(String id) => _favorites.containsKey(id);
  Set<String> get favorites => Set.unmodifiable(_favorites.keys);

  /// Adds or removes [recipe]; the full recipe is stored, not just its id.
  void toggleFavorite(Recipe recipe) {
    final removed = _favorites.remove(recipe.id) != null;
    if (!removed) _favorites[recipe.id] = recipe;
    debugPrint('$_tag ${removed ? 'unfavorited' : 'favorited'} '
        '"${recipe.title}" (${_favorites.length} favorites)');
    _saveFavorites();
    notifyListeners();
  }

  /// True if a *different* favorite already has the same title.
  bool isTitleAlreadySaved(String id, String title) {
    final key = _titleKey(title);
    return _favorites.values
        .any((r) => r.id != id && _titleKey(r.title) == key);
  }

  void _saveFavorites() => _store.setJson(
        StorageKeys.favoriteRecipes,
        _favorites.values.map((r) => r.toJson()).toList(),
      );

  static String _titleKey(String title) => title.trim().toLowerCase();

  // ── Generated recipes (real AI only, newest first) ─────────────────────
  static const _maxGenerated = 50;
  final List<Recipe> _generatedRecipes = [];
  List<Recipe> get generatedRecipes => List.unmodifiable(_generatedRecipes);

  Recipe? generatedById(String id) =>
      _generatedRecipes.where((r) => r.id == id).firstOrNull;

  /// Finds a recipe anywhere: AI-generated, favorites, then the mock catalog.
  Recipe? recipeByIdOrNull(String id) =>
      generatedById(id) ??
      _favorites[id] ??
      MockRecipes.all.where((r) => r.id == id).firstOrNull;

  void addGeneratedRecipe(Recipe recipe) {
    _generatedRecipes.insert(0, recipe);
    if (_generatedRecipes.length > _maxGenerated) {
      _generatedRecipes.removeRange(_maxGenerated, _generatedRecipes.length);
    }
    _store.setJson(
      StorageKeys.generatedRecipes,
      _generatedRecipes.map((r) => r.toJson()).toList(),
    );
    notifyListeners();
  }

  // ── Swipe deck ──────────────────────────────────────────────────────────
  List<Recipe> _swipeDeck = [];
  final Set<String> _liked = {};
  final Set<String> _passed = {};

  List<Recipe> get swipeDeck => _swipeDeck;
  Set<String> get liked => Set.unmodifiable(_liked);

  void seedSwipeDeck(List<Recipe> recipes) {
    _swipeDeck = List.of(recipes);
    notifyListeners();
  }

  /// A right swipe also favorites the card, unless that title is saved.
  void swipe({required bool liked}) {
    if (_swipeDeck.isEmpty) return;
    final card = _swipeDeck.removeAt(0);
    if (liked) {
      _liked.add(card.id);
      if (!isFavorite(card.id) && !isTitleAlreadySaved(card.id, card.title)) {
        _favorites[card.id] = card;
        _saveFavorites();
      }
    } else {
      _passed.add(card.id);
    }
    notifyListeners();
  }
}

/// Result of one generation attempt: the recipe and whether real AI made it.
class _Generation {
  final Recipe recipe;
  final bool fromAi;
  final String? fallbackReason;

  const _Generation.ai(this.recipe)
      : fromAi = true,
        fallbackReason = null;

  const _Generation.fallback(this.recipe, String this.fallbackReason)
      : fromAi = false;
}
