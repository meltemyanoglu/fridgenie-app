import 'package:flutter/foundation.dart';

import '../data/models/enums.dart';
import '../data/models/recipe.dart';
import '../data/services/ai_service.dart';
import 'user_provider.dart';

enum RequestState { idle, loading, success, error }

class RecipeProvider extends ChangeNotifier {
  final AIService _ai;
  final UserProvider _userProvider;

  RecipeProvider({
    required AIService aiService,
    required UserProvider userProvider,
  })  : _ai = aiService,
        _userProvider = userProvider;

  // ── Suggestions ────────────────────────────────────────────────────────
  List<RankedRecipe> _suggestions = [];
  RecipeCategory? _activeCategory;
  RequestState _suggestionsState = RequestState.idle;

  List<RankedRecipe> get suggestions => _suggestions;
  RecipeCategory? get activeCategory => _activeCategory;
  RequestState get suggestionsState => _suggestionsState;

  void setActiveCategory(RecipeCategory? cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  Future<void> generateSuggestions(Set<String> ingredientIds) async {
    _suggestionsState = RequestState.loading;
    notifyListeners();
    try {
      _suggestions = await _ai.suggestRecipes(
        ingredientIds: ingredientIds,
        profile: _userProvider.profile,
        category: _activeCategory,
      );
      _suggestionsState = RequestState.success;
    } catch (_) {
      _suggestionsState = RequestState.error;
    }
    notifyListeners();
  }

  // ── Mood-based ─────────────────────────────────────────────────────────
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

  // ── Surprise Me ────────────────────────────────────────────────────────
  RankedRecipe? _surprise;
  RankedRecipe? get surprise => _surprise;

  Future<void> rollSurprise() async {
    _suggestionsState = RequestState.loading;
    notifyListeners();
    _surprise = await _ai.surpriseMe(profile: _userProvider.profile);
    _suggestionsState = RequestState.success;
    notifyListeners();
  }

  // ── Challenge ──────────────────────────────────────────────────────────
  List<RankedRecipe> _challengeResults = [];
  List<RankedRecipe> get challengeResults => _challengeResults;

  Future<void> runChallenge(List<String> ids) async {
    _challengeResults = await _ai.challenge3Ingredients(ids);
    notifyListeners();
  }

  // ── Leftover Rescue ────────────────────────────────────────────────────
  List<RankedRecipe> _rescueResults = [];
  List<RankedRecipe> get rescueResults => _rescueResults;

  Future<void> runRescue(Set<String> ids) async {
    _rescueResults = await _ai.rescueLeftovers(
      ingredientIds: ids,
      profile: _userProvider.profile,
    );
    notifyListeners();
  }

  // ── Favorites ──────────────────────────────────────────────────────────
  final Set<String> _favorites = {};
  bool isFavorite(String id) => _favorites.contains(id);
  Set<String> get favorites => Set.unmodifiable(_favorites);

  void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
  }

  // ── Generated recipes (AI) ─────────────────────────────────────────────
  // Recipes invented by Gemini and held in memory for this session. When the
  // user taps "Save", we just add the id to favorites — the recipe object is
  // already kept here so lookups by id keep working.
  final List<Recipe> _generatedRecipes = [];
  List<Recipe> get generatedRecipes =>
      List.unmodifiable(_generatedRecipes);

  Recipe? generatedById(String id) {
    for (final r in _generatedRecipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  void addGeneratedRecipe(Recipe recipe) {
    // Most-recent-first.
    _generatedRecipes.insert(0, recipe);
    notifyListeners();
  }

  // ── Swipe deck (Tinder-style discovery) ────────────────────────────────
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
    } else {
      _passed.add(card.id);
    }
    notifyListeners();
  }
}
