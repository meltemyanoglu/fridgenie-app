import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock/mock_recipes.dart';
import '../data/models/enums.dart';
import '../data/models/recipe.dart';
import '../data/services/ai_service.dart';
import '../data/services/gemini_service.dart';
import 'user_provider.dart';

enum RequestState { idle, loading, success, error }

class RecipeProvider extends ChangeNotifier {
  final AIService _ai;
  final UserProvider _userProvider;
  final GeminiService? _gemini;

  RecipeProvider({
    required AIService aiService,
    required UserProvider userProvider,
    GeminiService? geminiService,
  })  : _ai = aiService,
        _userProvider = userProvider,
        _gemini = geminiService {
    _loadFavorites();
  }

  bool get geminiAvailable => _gemini?.isAvailable == true;

  // ── Suggestions (mock AI) ───────────────────────────────────────────────
  List<RankedRecipe> _suggestions = [];
  RecipeCategory? _activeCategory;
  RequestState _suggestionsState = RequestState.idle;
  String? _suggestionsError;

  List<RankedRecipe> get suggestions => _suggestions;
  RecipeCategory? get activeCategory => _activeCategory;
  RequestState get suggestionsState => _suggestionsState;
  String? get suggestionsError => _suggestionsError;

  void setActiveCategory(RecipeCategory? cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  Future<void> generateSuggestions(Set<String> ingredientIds) async {
    _suggestionsState = RequestState.loading;
    _suggestionsError = null;
    notifyListeners();
    try {
      _suggestions = await _ai.suggestRecipes(
        ingredientIds: ingredientIds,
        profile: _userProvider.profile,
        category: _activeCategory,
      );
      _suggestionsState = RequestState.success;
    } catch (e) {
      _suggestionsState = RequestState.error;
      _suggestionsError = e.toString();
    }
    notifyListeners();
  }

  // ── Gemini recipe generation ────────────────────────────────────────────
  RequestState _geminiState = RequestState.idle;
  String? _geminiError;
  bool _lastGenerationUsedGemini = false;

  RequestState get geminiState => _geminiState;
  String? get geminiError => _geminiError;
  bool get lastGenerationUsedGemini => _lastGenerationUsedGemini;

  /// Generate a bespoke recipe with Gemini (falls back to mock on failure).
  /// Returns the resulting [RankedRecipe] so callers can navigate to detail.
  Future<RankedRecipe?> generateWithGemini({
    required List<String> ingredientIds,
    GenieMode mode = GenieMode.standard,
  }) async {
    _geminiState = RequestState.loading;
    _geminiError = null;
    notifyListeners();

    try {
      RecipeResult result;

      if (_gemini != null) {
        result = await _gemini.generateRecipe(
          ingredientIds: ingredientIds,
          dietary: _userProvider.profile.dietary,
          mood: _userProvider.profile.defaultMood,
          cuisine: _userProvider.profile.favoriteCuisines.isNotEmpty
              ? _userProvider.profile.favoriteCuisines.first
              : null,
          skill: _userProvider.profile.skill,
          mode: mode,
          avoidTitles: _generatedRecipes.map((r) => r.title).take(10).toList(),
        );
      } else {
        // No Gemini key — use mock fallback directly.
        final mockRecipe = await _ai.surpriseMe(profile: _userProvider.profile);
        result = RecipeResult.fromMock(
          mockRecipe.recipe,
          reason: 'Add a Gemini API key to unlock real AI generation.',
        );
      }

      _lastGenerationUsedGemini = result.fromGemini;

      if (result.fallbackReason != null) {
        _geminiError = result.fallbackReason;
      }

      addGeneratedRecipe(result.recipe);

      _geminiState = RequestState.success;
      notifyListeners();

      return RankedRecipe(
        recipe: result.recipe,
        matchScore: 1.0,
        haveIngredients: result.recipe.requiredIngredientIds
            .where(ingredientIds.contains)
            .toList(),
        missingIngredients: result.recipe.requiredIngredientIds
            .where((id) => !ingredientIds.contains(id))
            .toList(),
        aiReason: result.recipe.whyRecommended,
      );
    } catch (e) {
      _geminiState = RequestState.error;
      _geminiError = 'Something went wrong. Try again in a moment.';
      notifyListeners();
      return null;
    }
  }

  // ── Mood-based ──────────────────────────────────────────────────────────
  List<RankedRecipe> _moodSuggestions = [];
  Mood? _activeMood;
  List<RankedRecipe> get moodSuggestions => _moodSuggestions;
  Mood? get activeMood => _activeMood;

  Future<void> suggestForMood(Mood mood, Set<String> ingredientIds) async {
    _activeMood = mood;
    _suggestionsState = RequestState.loading;
    notifyListeners();
    _moodSuggestions = await _ai.suggestRecipes(
      ingredientIds: ingredientIds,
      profile: _userProvider.profile,
      mood: mood,
    );
    _suggestionsState = RequestState.success;
    notifyListeners();
  }

  // ── Surprise Me ─────────────────────────────────────────────────────────
  RankedRecipe? _surprise;
  RankedRecipe? get surprise => _surprise;

  Future<void> rollSurprise() async {
    _suggestionsState = RequestState.loading;
    notifyListeners();

    if (_gemini != null) {
      // Try Gemini surprise mode — fall back silently to mock.
      final fakeIds = <String>[];
      final result = await _gemini.generateRecipe(
        ingredientIds: fakeIds,
        mode: GenieMode.surpriseMe,
      );
      _surprise = RankedRecipe(
        recipe: result.recipe,
        matchScore: 1.0,
        haveIngredients: const [],
        missingIngredients: const [],
        aiReason: result.recipe.whyRecommended,
      );
    } else {
      _surprise = await _ai.surpriseMe(profile: _userProvider.profile);
    }

    _suggestionsState = RequestState.success;
    notifyListeners();
  }

  // ── Challenge ───────────────────────────────────────────────────────────
  List<RankedRecipe> _challengeResults = [];
  List<RankedRecipe> get challengeResults => _challengeResults;

  Future<void> runChallenge(List<String> ids) async {
    _challengeResults = await _ai.challenge3Ingredients(ids);
    notifyListeners();
  }

  // ── Leftover Rescue ─────────────────────────────────────────────────────
  List<RankedRecipe> _rescueResults = [];
  List<RankedRecipe> get rescueResults => _rescueResults;

  Future<void> runRescue(Set<String> ids) async {
    _rescueResults = await _ai.rescueLeftovers(
      ingredientIds: ids,
      profile: _userProvider.profile,
    );
    notifyListeners();
  }

  // ── Favorites — persisted to SharedPreferences ─────────────────────────
  final Set<String> _favorites = {};
  // id → title cache so duplicate check works even across sessions
  final Map<String, String> _favoriteTitles = {};

  bool isFavorite(String id) => _favorites.contains(id);
  Set<String> get favorites => Set.unmodifiable(_favorites);

  SharedPreferences? _prefs;

  static const _kFavoritesKey = 'fridgenie.favorites';
  static const _kFavoriteTitlesKey = 'fridgenie.favorite_titles';
  static const _kGeneratedKey = 'fridgenie.generated_recipes';
  static const _kMaxGenerated = 50;

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getStringList(_kFavoritesKey) ?? [];
    _favorites.addAll(saved);
    _loadGeneratedRecipesFromPrefs();
    _loadFavoriteTitlesFromPrefs();
    _deduplicateFavorites();
    notifyListeners();
  }

  void _loadGeneratedRecipesFromPrefs() {
    final raw = _prefs?.getString(_kGeneratedKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _generatedRecipes.clear();
      for (final item in list) {
        _generatedRecipes.add(Recipe.fromJson(item as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  void _loadFavoriteTitlesFromPrefs() {
    final raw = _prefs?.getString(_kFavoriteTitlesKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((k, v) => _favoriteTitles[k] = v as String);
    } catch (_) {}
  }

  /// Remove orphaned IDs (recipe not found anywhere) and title-duplicates.
  void _deduplicateFavorites() {
    final seenTitles = <String>{};
    final toRemove = <String>[];
    for (final id in _favorites.toList()) {
      final title = _favoriteTitles[id] ?? recipeByIdOrNull(id)?.title;
      if (title == null) {
        // Can't resolve this recipe — orphan, remove it.
        toRemove.add(id);
        continue;
      }
      final key = title.trim().toLowerCase();
      if (seenTitles.contains(key)) {
        toRemove.add(id);
      } else {
        seenTitles.add(key);
      }
    }
    if (toRemove.isEmpty) return;
    for (final id in toRemove) {
      _favorites.remove(id);
      _favoriteTitles.remove(id);
    }
    _saveFavorites();
    _saveFavoriteTitles();
  }

  void _saveFavorites() {
    _prefs?.setStringList(_kFavoritesKey, _favorites.toList());
  }

  void _saveFavoriteTitles() {
    _prefs?.setString(_kFavoriteTitlesKey, jsonEncode(_favoriteTitles));
  }

  void _saveGeneratedRecipes() {
    final toSave = _generatedRecipes.take(_kMaxGenerated).toList();
    _prefs?.setString(
      _kGeneratedKey,
      jsonEncode(toSave.map((r) => r.toJson()).toList()),
    );
  }

  void toggleFavorite(String id, {String? title}) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
      _favoriteTitles.remove(id);
    } else {
      _favorites.add(id);
      if (title != null) _favoriteTitles[id] = title;
    }
    notifyListeners();
    _saveFavorites();
    _saveFavoriteTitles();
  }

  // ── Generated recipes (Gemini / mock) ──────────────────────────────────
  final List<Recipe> _generatedRecipes = [];
  List<Recipe> get generatedRecipes => List.unmodifiable(_generatedRecipes);

  Recipe? generatedById(String id) {
    for (final r in _generatedRecipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  Recipe? recipeByIdOrNull(String id) {
    final gen = generatedById(id);
    if (gen != null) return gen;
    try {
      return MockRecipes.all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// True if a *different* favorited recipe already has the same title.
  bool isTitleAlreadySaved(String id, String title) {
    final normalised = title.trim().toLowerCase();
    for (final favId in _favorites) {
      if (favId == id) continue;
      // Check persisted title map first (works across sessions)
      final saved = _favoriteTitles[favId];
      if (saved != null && saved.trim().toLowerCase() == normalised) return true;
      // Fallback: live recipe lookup
      final r = recipeByIdOrNull(favId);
      if (r != null && r.title.trim().toLowerCase() == normalised) return true;
    }
    return false;
  }

  void addGeneratedRecipe(Recipe recipe) {
    _generatedRecipes.insert(0, recipe);
    _saveGeneratedRecipes();
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

  void swipe({required bool liked}) {
    if (_swipeDeck.isEmpty) return;
    final card = _swipeDeck.removeAt(0);
    if (liked) {
      _liked.add(card.id);
      _favorites.add(card.id);
      _favoriteTitles[card.id] = card.title;
      _saveFavorites();
      _saveFavoriteTitles();
    } else {
      _passed.add(card.id);
    }
    notifyListeners();
  }
}
