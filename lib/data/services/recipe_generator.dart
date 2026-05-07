import 'dart:convert';

import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

import '../mock/mock_ingredients.dart';
import '../models/enums.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'ingredient_recognizer.dart' show RecognizerException;

/// Talks to the Cloudflare Worker's `/generate-recipe` endpoint and turns the
/// JSON response into a real [Recipe] object the rest of the app can render.
///
/// The Worker holds the Gemini API key — no secrets in the Flutter binary.
class RecipeGenerator {
  /// Same backend as the ingredient recognizer; we just hit a different path.
  final String backendUrl;
  final http.Client _client;
  final Duration timeout;

  RecipeGenerator({
    required this.backendUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  /// Hit `/generate-recipe` and parse the result into a [Recipe]. Pass the
  /// user's current ingredient set (catalog ids OR free-text names) plus
  /// optional context to bias the generation.
  Future<Recipe> generate({
    required List<String> ingredients,
    Set<DietaryPreference> dietary = const {},
    Mood? mood,
    CuisineType? cuisine,
    CookingSkill? skill,
    List<String> avoidTitles = const [],
  }) async {
    if (ingredients.isEmpty) {
      throw const RecognizerException('Pick at least one ingredient first.');
    }

    final endpoint = backendUrl.replaceAll(RegExp(r'/+$'), '') +
        '/generate-recipe';

    // Translate catalog ids → human names so Gemini gets natural language.
    final names = ingredients
        .map((id) => MockIngredients.byId(id)?.name ?? id)
        .map((s) => s.toLowerCase())
        .toList();

    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ingredients': names,
              'dietary': dietary.map((d) => d.name).toList(),
              if (mood != null) 'mood': mood.name,
              if (cuisine != null) 'cuisine': cuisine.name,
              if (skill != null) 'skill': skill.name,
              'avoidTitles': avoidTitles,
            }),
          )
          .timeout(timeout);
    } catch (e) {
      throw RecognizerException('Network error: $e');
    }

    if (res.statusCode != 200) {
      String detail = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['error'] is String) detail = j['error'] as String;
      } catch (_) {}
      throw RecognizerException(
        'Generator returned ${res.statusCode}: $detail',
      );
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw const RecognizerException('Backend returned invalid JSON.');
    }

    final raw = body['recipe'];
    if (raw is! Map<String, dynamic>) {
      throw const RecognizerException('Backend response had no recipe.');
    }

    return _toRecipe(raw, ingredientHints: ingredients);
  }

  // ── JSON → Recipe ────────────────────────────────────────────────────────

  static Recipe _toRecipe(
    Map<String, dynamic> j, {
    required List<String> ingredientHints,
  }) {
    final id = 'gen_${DateTime.now().millisecondsSinceEpoch}_'
        '${j['title'].hashCode.abs()}';

    final category = _parseCategory(j['category'] as String?);
    final difficulty = _parseDifficulty(j['difficulty'] as String?);
    final nutrition = _parseNutrition(j['nutrition']);
    final steps = _parseSteps(j['steps']);
    final subs = _parseSubs(j['substitutions']);
    final moods = _parseMoods(j['moods']);
    final cuisines = _parseCuisines(j['cuisines']);
    final dietary = _parseDietary(j['dietary']);

    final required =
        _matchIngredientIds(j['ingredients'], ingredientHints: ingredientHints);
    final optional = _matchIngredientIds(
      j['optionalIngredients'],
      ingredientHints: ingredientHints,
    );

    return Recipe(
      id: id,
      title: (j['title'] as String?)?.trim().isNotEmpty == true
          ? j['title'] as String
          : 'Genie Original',
      tagline: (j['tagline'] as String?) ?? '',
      emoji: (j['emoji'] as String?)?.trim().isNotEmpty == true
          ? j['emoji'] as String
          : '🍽️',
      photoUrl: '', // generated recipes use the gradient + emoji fallback
      gradientColors: _gradientFor(category),
      category: category,
      difficulty: difficulty,
      cookMinutes: (j['cookMinutes'] is num)
          ? (j['cookMinutes'] as num).round()
          : 25,
      servings:
          (j['servings'] is num) ? (j['servings'] as num).round() : 2,
      nutrition: nutrition,
      requiredIngredientIds: required,
      optionalIngredientIds: optional,
      steps: steps,
      substitutions: subs,
      matchingMoods: moods.isNotEmpty ? moods : const [Mood.cozy],
      cuisines: cuisines,
      dietaryFits: dietary,
      whyRecommended: (j['whyRecommended'] as String?) ??
          'Genie improvised this one for what you have.',
      tags: (j['tags'] is List)
          ? (j['tags'] as List)
              .whereType<String>()
              .toList(growable: false)
          : const ['ai-generated'],
    );
  }

  // ── parsers ──────────────────────────────────────────────────────────────

  static RecipeCategory _parseCategory(String? raw) {
    final v = (raw ?? '').toLowerCase().trim();
    for (final c in RecipeCategory.values) {
      if (c.name.toLowerCase() == v) return c;
    }
    if (v == 'use-it-up' || v == 'use_it_up') return RecipeCategory.useItUp;
    return RecipeCategory.comfort;
  }

  static DifficultyLevel _parseDifficulty(String? raw) {
    final v = (raw ?? '').toLowerCase().trim();
    for (final d in DifficultyLevel.values) {
      if (d.name.toLowerCase() == v) return d;
    }
    return DifficultyLevel.easy;
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
      calories: 400,
      proteinG: 15,
      carbsG: 45,
      fatG: 15,
    );
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
    if (raw is! List) return const [];
    final out = <Mood>{};
    for (final s in raw.whereType<String>()) {
      final v = s.toLowerCase().trim();
      for (final m in Mood.values) {
        if (m.name.toLowerCase() == v) {
          out.add(m);
          break;
        }
      }
    }
    return out.toList();
  }

  static List<CuisineType> _parseCuisines(dynamic raw) {
    if (raw is! List) return const [];
    final out = <CuisineType>{};
    for (final s in raw.whereType<String>()) {
      final v = s.toLowerCase().trim();
      for (final c in CuisineType.values) {
        if (c.name.toLowerCase() == v) {
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
      final v = s.toLowerCase().trim();
      for (final d in DietaryPreference.values) {
        if (d.name.toLowerCase() == v) {
          out.add(d);
          break;
        }
      }
    }
    return out.toList();
  }

  /// Best-effort: prefer the user's actual catalog ids; otherwise fuzzy-match
  /// the AI's free-text against MockIngredients; otherwise drop the entry.
  static List<String> _matchIngredientIds(
    dynamic raw, {
    required List<String> ingredientHints,
  }) {
    if (raw is! List) return const [];
    final hintSet = ingredientHints.toSet();
    final out = <String>{};

    for (final s in raw.whereType<String>()) {
      final clean = s.toLowerCase().trim();
      if (clean.isEmpty) continue;

      // 1. exact id we already passed in
      if (hintSet.contains(clean)) {
        out.add(clean);
        continue;
      }
      // 2. exact id (snake_case)
      final byId =
          MockIngredients.byId(clean.replaceAll(RegExp(r'\s+'), '_'));
      if (byId != null) {
        out.add(byId.id);
        continue;
      }
      // 3. fuzzy name match
      Ingredient? hit;
      for (final i in MockIngredients.all) {
        final name = i.name.toLowerCase();
        if (name == clean ||
            name.contains(clean) ||
            clean.contains(name)) {
          hit = i;
          break;
        }
      }
      if (hit != null) out.add(hit.id);
    }
    return out.toList();
  }

  /// Pick a tasteful gradient based on category — generated recipes don't
  /// supply gradients, but we still want each card to feel intentional.
  static List<Color> _gradientFor(RecipeCategory cat) {
    switch (cat) {
      case RecipeCategory.comfort:
        return const [Color(0xFFFFE7B8), Color(0xFFFFB088)];
      case RecipeCategory.healthy:
        return const [Color(0xFF8AD49C), Color(0xFFFFD23F)];
      case RecipeCategory.quick:
        return const [Color(0xFFFFD23F), Color(0xFFFFA630)];
      case RecipeCategory.budget:
        return const [Color(0xFFFFD23F), Color(0xFF8AD49C)];
      case RecipeCategory.useItUp:
        return const [Color(0xFFE5854A), Color(0xFFFF6B6B)];
    }
  }
}
