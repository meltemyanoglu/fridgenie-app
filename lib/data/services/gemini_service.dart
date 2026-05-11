import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

import '../mock/mock_ingredients.dart';
import '../mock/mock_recipes.dart';
import '../models/enums.dart';
import '../models/recipe.dart';

/// Cooking context passed to Gemini to influence prompt style.
enum GenieMode {
  standard,
  surpriseMe,
  challenge3,
  leftoversRescue,
  healthyQuick,
  moodBased,
}

/// Direct HTTP client for Google Gemini API (v1beta).
///
/// The API key is never stored in source — pass it at build time:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// When [isAvailable] is false (no key configured), every method falls back
/// gracefully to mock data so the UI never breaks.
class GeminiService {
  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final String _apiKey;
  final http.Client _client;
  final Duration _timeout;

  GeminiService._({
    required String apiKey,
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  })  : _apiKey = apiKey,
        _client = client ?? http.Client(),
        _timeout = timeout;

  /// Factory that reads the key from the build environment.
  /// Returns null if no key is configured — callers should show "demo mode".
  static GeminiService? create() {
    const key = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (key.isEmpty) return null;
    return GeminiService._(apiKey: key);
  }

  bool get isAvailable => _apiKey.isNotEmpty;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Generate a single bespoke recipe from the user's ingredient list.
  /// On any error, falls back to a plausible mock recipe instead of throwing.
  Future<RecipeResult> generateRecipe({
    required List<String> ingredientIds,
    Set<DietaryPreference> dietary = const {},
    Mood? mood,
    CuisineType? cuisine,
    CookingSkill? skill,
    GenieMode mode = GenieMode.standard,
    List<String> avoidTitles = const [],
  }) async {
    final names = _idsToNames(ingredientIds);
    if (names.isEmpty) {
      return RecipeResult.fromMock(_mockFallback(ingredientIds, mode),
          reason: 'No ingredients selected — showing a demo recipe.');
    }

    try {
      final prompt = _buildSinglePrompt(
        ingredients: names,
        dietary: dietary,
        mood: mood,
        cuisine: cuisine,
        skill: skill,
        mode: mode,
        avoidTitles: avoidTitles,
      );
      final json = await _callGemini(prompt);
      final recipe = _parseRecipe(json, ingredientIds);
      return RecipeResult.fromGemini(recipe);
    } catch (e) {
      debugPrint('[GeminiService] generateRecipe error: $e');
      return RecipeResult.fromMock(
        _mockFallback(ingredientIds, mode),
        reason: 'Genie is taking a nap — showing a demo recipe instead.',
      );
    }
  }

  /// Generate a list of ranked recipe suggestions.
  /// On any error, returns an empty list (callers should use mock fallback).
  Future<List<RankedResult>> suggestRecipes({
    required Set<String> ingredientIds,
    Set<DietaryPreference> dietary = const {},
    Mood? mood,
    CuisineType? cuisine,
    CookingSkill? skill,
    GenieMode mode = GenieMode.standard,
    int count = 4,
  }) async {
    final names = _idsToNames(ingredientIds.toList());
    if (names.isEmpty) return const [];

    try {
      final prompt = _buildListPrompt(
        ingredients: names,
        dietary: dietary,
        mood: mood,
        cuisine: cuisine,
        skill: skill,
        mode: mode,
        count: count,
      );
      final raw = await _callGeminiList(prompt);
      return raw
          .map((j) => _parseRanked(j, ingredientIds.toList()))
          .toList();
    } catch (e) {
      debugPrint('[GeminiService] suggestRecipes error: $e');
      return const [];
    }
  }

  // ── Gemini HTTP ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callGemini(String prompt) async {
    final raw = await _rawCall(prompt);
    // When responseMimeType is json, Gemini may return a JSON object or array.
    // We always ask for an object here — unwrap list if needed.
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return raw.first as Map<String, dynamic>;
    }
    throw const GeminiException('Unexpected JSON structure from Gemini.');
  }

  Future<List<Map<String, dynamic>>> _callGeminiList(String prompt) async {
    final raw = await _rawCall(prompt);
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map<String, dynamic>) {
      // Sometimes Gemini wraps the list in a key.
      for (final v in raw.values) {
        if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  Future<dynamic> _rawCall(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.82,
        'topP': 0.95,
        'maxOutputTokens': 8192,
      },
    });

    final res = await _client
        .post(
          url,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      String detail = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['error'] is Map) {
          detail = (j['error'] as Map)['message']?.toString() ?? detail;
        }
      } catch (_) {}
      throw GeminiException('Gemini ${res.statusCode}: $detail');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('Gemini returned no candidates.');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final finishReason = candidate['finishReason'] as String?;
    if (finishReason == 'MAX_TOKENS') {
      throw const GeminiException('Response was cut off — try again.');
    }

    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw const GeminiException('Gemini returned empty content.');
    }

    final text = (parts.first['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) throw const GeminiException('Gemini returned empty text.');

    return jsonDecode(text);
  }

  // ── Prompt builders ─────────────────────────────────────────────────────

  String _buildSinglePrompt({
    required List<String> ingredients,
    required Set<DietaryPreference> dietary,
    required Mood? mood,
    required CuisineType? cuisine,
    required CookingSkill? skill,
    required GenieMode mode,
    required List<String> avoidTitles,
  }) {
    final parts = <String>[
      'You are Fridgenie, a warm and creative AI chef.',
      'Generate exactly ONE delicious recipe using the provided ingredients.',
      '',
      'Available ingredients: ${ingredients.join(', ')}',
      if (dietary.isNotEmpty)
        'Dietary requirements: ${dietary.map((d) => d.label).join(', ')}',
      if (mood != null) 'User mood: ${mood.label} — ${mood.tagline}',
      if (cuisine != null) 'Preferred cuisine style: ${cuisine.label}',
      if (skill != null) 'Cooking skill level: ${skill.label}',
      _modeInstruction(mode),
      if (avoidTitles.isNotEmpty)
        'Do NOT use any of these titles: ${avoidTitles.join(', ')}',
      '',
      'Return ONLY valid JSON — no markdown, no prose — with this exact structure:',
      _singleRecipeSchema(),
    ];
    return parts.join('\n');
  }

  String _buildListPrompt({
    required List<String> ingredients,
    required Set<DietaryPreference> dietary,
    required Mood? mood,
    required CuisineType? cuisine,
    required CookingSkill? skill,
    required GenieMode mode,
    required int count,
  }) {
    final parts = <String>[
      'You are Fridgenie, a warm and creative AI chef.',
      'Suggest exactly $count recipes using the provided ingredients.',
      '',
      'Available ingredients: ${ingredients.join(', ')}',
      if (dietary.isNotEmpty)
        'Dietary requirements: ${dietary.map((d) => d.label).join(', ')}',
      if (mood != null) 'User mood: ${mood.label} — ${mood.tagline}',
      if (cuisine != null) 'Preferred cuisine style: ${cuisine.label}',
      if (skill != null) 'Cooking skill level: ${skill.label}',
      _modeInstruction(mode),
      '',
      'Return ONLY a valid JSON array — no markdown, no prose — with $count objects, each with this structure:',
      _singleRecipeSchema(),
    ];
    return parts.join('\n');
  }

  String _modeInstruction(GenieMode mode) {
    switch (mode) {
      case GenieMode.standard:
        return 'Create a well-balanced, satisfying recipe.';
      case GenieMode.surpriseMe:
        return 'Be creative and surprising! Combine ingredients in an unexpected but delightful way.';
      case GenieMode.challenge3:
        return 'CHALLENGE: use ONLY the first 3 ingredients listed. Keep it minimal and clever.';
      case GenieMode.leftoversRescue:
        return 'LEFTOVER RESCUE: use as many of the listed ingredients as possible to reduce food waste.';
      case GenieMode.healthyQuick:
        return 'HEALTHY & QUICK: must be under 20 minutes, high protein, lower calorie, nutrient-dense.';
      case GenieMode.moodBased:
        return 'MOOD COOKING: tailor every aspect of the recipe — flavors, textures, presentation — to match the user\'s current mood.';
    }
  }

  String _singleRecipeSchema() => '''
{
  "title": "Recipe Name",
  "tagline": "One catchy line, max 60 chars",
  "emoji": "🍳",
  "category": "comfort",
  "difficulty": "easy",
  "cookMinutes": 20,
  "servings": 2,
  "nutrition": {
    "calories": 400,
    "proteinG": 20,
    "carbsG": 45,
    "fatG": 15
  },
  "ingredients": ["ingredient1", "ingredient2"],
  "optionalIngredients": ["optional1"],
  "steps": [
    {"order": 1, "text": "Step description here", "minutes": 5},
    {"order": 2, "text": "Another step", "minutes": 10}
  ],
  "substitutions": [
    {"missing": "ingredient", "swap": "alternative", "reason": "why it works"}
  ],
  "moods": ["cozy"],
  "cuisines": ["italian"],
  "dietary": ["vegetarian"],
  "whyRecommended": "Why this is perfect right now (1–2 sentences)",
  "tags": ["quick", "one-pan"],
  "matchScore": 0.9
}

Valid values:
  category: comfort | healthy | quick | budget | useItUp
  difficulty: easy | medium | hard
  moods: cozy | energetic | calm | celebratory | adventurous | comforted
  cuisines: italian | mexican | japanese | indian | mediterranean | middleEastern | turkish | korean | thai | chinese | french | american
  dietary: vegetarian | vegan | pescatarian | glutenFree | dairyFree | keto | halal | kosher | noRestrictions''';

  // ── JSON → Model parsers ─────────────────────────────────────────────────

  Recipe _parseRecipe(Map<String, dynamic> j, List<String> hints) {
    final id =
        'gem_${DateTime.now().millisecondsSinceEpoch}_${j['title'].hashCode.abs()}';

    final category = _parseCategory(j['category'] as String?);
    final difficulty = _parseDifficulty(j['difficulty'] as String?);

    return Recipe(
      id: id,
      title: _str(j['title'], 'Genie Special'),
      tagline: _str(j['tagline'], ''),
      emoji: _str(j['emoji'], '🍽️'),
      photoUrl: '',
      gradientColors: _gradientFor(category),
      category: category,
      difficulty: difficulty,
      cookMinutes: (j['cookMinutes'] as num?)?.round() ?? 25,
      servings: (j['servings'] as num?)?.round() ?? 2,
      nutrition: _parseNutrition(j['nutrition']),
      requiredIngredientIds: _matchIds(j['ingredients'], hints),
      optionalIngredientIds: _matchIds(j['optionalIngredients'], hints),
      steps: _parseSteps(j['steps']),
      substitutions: _parseSubs(j['substitutions']),
      matchingMoods: _parseMoods(j['moods']),
      cuisines: _parseCuisines(j['cuisines']),
      dietaryFits: _parseDietary(j['dietary']),
      whyRecommended: _str(
          j['whyRecommended'], 'Genie cooked this up just for you.'),
      tags: _strList(j['tags'], ['ai-generated']),
    );
  }

  RankedResult _parseRanked(Map<String, dynamic> j, List<String> hints) {
    final recipe = _parseRecipe(j, hints);
    final score = ((j['matchScore'] as num?)?.toDouble() ?? 0.75).clamp(0.0, 1.0);
    final have = recipe.requiredIngredientIds
        .where(hints.contains)
        .toList();
    final missing = recipe.requiredIngredientIds
        .where((id) => !hints.contains(id))
        .toList();
    return RankedResult(
      recipe: recipe,
      matchScore: score,
      haveIngredients: have,
      missingIngredients: missing,
      aiReason: _str(j['whyRecommended'], recipe.whyRecommended),
      fromGemini: true,
    );
  }

  // ── Parsers ─────────────────────────────────────────────────────────────

  static RecipeCategory _parseCategory(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'healthy':
        return RecipeCategory.healthy;
      case 'quick':
        return RecipeCategory.quick;
      case 'budget':
        return RecipeCategory.budget;
      case 'useitup':
      case 'use-it-up':
      case 'use_it_up':
        return RecipeCategory.useItUp;
      default:
        return RecipeCategory.comfort;
    }
  }

  static DifficultyLevel _parseDifficulty(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.easy;
    }
  }

  static NutritionInfo _parseNutrition(dynamic raw) {
    if (raw is Map) {
      return NutritionInfo(
        calories: (raw['calories'] as num?)?.round() ?? 400,
        proteinG: (raw['proteinG'] as num?)?.round() ?? 15,
        carbsG: (raw['carbsG'] as num?)?.round() ?? 45,
        fatG: (raw['fatG'] as num?)?.round() ?? 15,
      );
    }
    return const NutritionInfo(
        calories: 400, proteinG: 15, carbsG: 45, fatG: 15);
  }

  static List<RecipeStep> _parseSteps(dynamic raw) {
    if (raw is! List) return const [];
    final out = <RecipeStep>[];
    for (var i = 0; i < raw.length; i++) {
      final s = raw[i];
      if (s is Map && s['text'] is String) {
        out.add(RecipeStep(
          order: (s['order'] as num?)?.round() ?? i + 1,
          text: s['text'] as String,
          minutes: (s['minutes'] as num?)?.round(),
        ));
      }
    }
    return out;
  }

  static List<Substitution> _parseSubs(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .where((s) => s['missing'] is String && s['swap'] is String)
        .map((s) => Substitution(
              missing: s['missing'] as String,
              swap: s['swap'] as String,
              reason: (s['reason'] as String?) ?? '',
            ))
        .toList();
  }

  static List<Mood> _parseMoods(dynamic raw) {
    if (raw is! List) return [Mood.cozy];
    final out = <Mood>{};
    for (final s in raw.whereType<String>()) {
      for (final m in Mood.values) {
        if (m.name.toLowerCase() == s.toLowerCase().trim()) {
          out.add(m);
          break;
        }
      }
    }
    return out.isEmpty ? [Mood.cozy] : out.toList();
  }

  static List<CuisineType> _parseCuisines(dynamic raw) {
    if (raw is! List) return const [];
    final out = <CuisineType>{};
    for (final s in raw.whereType<String>()) {
      for (final c in CuisineType.values) {
        if (c.name.toLowerCase() == s.toLowerCase().trim()) {
          out.add(c);
          break;
        }
      }
    }
    return out.toList();
  }

  static List<DietaryPreference> _parseDietary(dynamic raw) {
    if (raw is! List) return const [];
    final out = <DietaryPreference>{};
    for (final s in raw.whereType<String>()) {
      for (final d in DietaryPreference.values) {
        if (d.name.toLowerCase() == s.toLowerCase().trim()) {
          out.add(d);
          break;
        }
      }
    }
    return out.toList();
  }

  /// Map AI ingredient names / ids back to catalog ids using fuzzy matching.
  static List<String> _matchIds(dynamic raw, List<String> hints) {
    if (raw is! List) return const [];
    final hintSet = hints.toSet();
    final out = <String>{};

    for (final s in raw.whereType<String>()) {
      final clean = s.trim().toLowerCase();
      if (clean.isEmpty) continue;

      if (hintSet.contains(clean)) {
        out.add(clean);
        continue;
      }
      final byId = MockIngredients.byId(clean.replaceAll(' ', '_'));
      if (byId != null) {
        out.add(byId.id);
        continue;
      }
      for (final i in MockIngredients.all) {
        final name = i.name.toLowerCase();
        if (name == clean || name.contains(clean) || clean.contains(name)) {
          out.add(i.id);
          break;
        }
      }
    }
    return out.toList();
  }

  static List<Color> _gradientFor(RecipeCategory cat) {
    switch (cat) {
      case RecipeCategory.comfort:
        return const [Color(0xFFFFE7B8), Color(0xFFFFB088)];
      case RecipeCategory.healthy:
        return const [Color(0xFF8AD49C), Color(0xFF3DA35D)];
      case RecipeCategory.quick:
        return const [Color(0xFFFFD23F), Color(0xFFFFA630)];
      case RecipeCategory.budget:
        return const [Color(0xFFFFD23F), Color(0xFF8AD49C)];
      case RecipeCategory.useItUp:
        return const [Color(0xFFE5854A), Color(0xFFFF6B6B)];
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _str(dynamic v, String fallback) =>
      (v is String && v.trim().isNotEmpty) ? v.trim() : fallback;

  static List<String> _strList(dynamic v, List<String> fallback) =>
      v is List ? v.whereType<String>().toList() : fallback;

  static List<String> _idsToNames(List<String> ids) => ids
      .map((id) => MockIngredients.byId(id)?.name ?? id)
      .map((s) => s.toLowerCase())
      .toList();

  static Recipe _mockFallback(List<String> ids, GenieMode mode) {
    // Pick from mock recipes based on mode.
    final all = MockRecipes.all;
    if (all.isEmpty) {
      return Recipe(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Simple Veggie Stir-Fry',
        tagline: 'Quick, healthy, and delicious.',
        emoji: '🥘',
        gradientColors: const [Color(0xFF8AD49C), Color(0xFF3DA35D)],
        category: RecipeCategory.healthy,
        difficulty: DifficultyLevel.easy,
        cookMinutes: 15,
        servings: 2,
        nutrition: const NutritionInfo(
            calories: 280, proteinG: 12, carbsG: 34, fatG: 10),
        requiredIngredientIds: ids.take(3).toList(),
        optionalIngredientIds: const [],
        steps: const [
          RecipeStep(order: 1, text: 'Heat oil in a pan over medium heat.'),
          RecipeStep(
              order: 2, text: 'Add vegetables and stir-fry for 5 minutes.', minutes: 5),
          RecipeStep(order: 3, text: 'Season to taste and serve immediately.'),
        ],
        substitutions: const [],
        matchingMoods: [Mood.energetic, Mood.calm],
        cuisines: const [],
        dietaryFits: [DietaryPreference.vegetarian, DietaryPreference.vegan],
        whyRecommended: 'Uses what you have and keeps it simple.',
        tags: const ['quick', 'healthy', 'demo'],
      );
    }

    switch (mode) {
      case GenieMode.surpriseMe:
        return all[DateTime.now().millisecond % all.length];
      case GenieMode.healthyQuick:
        return all.firstWhere(
          (r) => r.category == RecipeCategory.healthy || r.cookMinutes <= 20,
          orElse: () => all.first,
        );
      case GenieMode.leftoversRescue:
        return all.firstWhere(
          (r) => r.category == RecipeCategory.useItUp,
          orElse: () => all.first,
        );
      default:
        return all.first;
    }
  }
}

/// Wrapper for a generated recipe that tells callers whether Gemini was used.
class RecipeResult {
  final Recipe recipe;
  final bool fromGemini;
  final String? fallbackReason;

  const RecipeResult._({
    required this.recipe,
    required this.fromGemini,
    this.fallbackReason,
  });

  factory RecipeResult.fromGemini(Recipe recipe) =>
      RecipeResult._(recipe: recipe, fromGemini: true);

  factory RecipeResult.fromMock(Recipe recipe, {String? reason}) =>
      RecipeResult._(recipe: recipe, fromGemini: false, fallbackReason: reason);
}

/// A ranked recipe from Gemini with match metadata.
class RankedResult {
  final Recipe recipe;
  final double matchScore;
  final List<String> haveIngredients;
  final List<String> missingIngredients;
  final String aiReason;
  final bool fromGemini;

  const RankedResult({
    required this.recipe,
    required this.matchScore,
    required this.haveIngredients,
    required this.missingIngredients,
    required this.aiReason,
    this.fromGemini = false,
  });

  int get matchPercent => (matchScore * 100).round();
}

/// Surfaced to the UI so it can show a friendly non-scary message.
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => message;
}
