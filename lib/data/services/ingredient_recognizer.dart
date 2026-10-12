import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../mock/mock_ingredients.dart';
import '../models/ingredient.dart';
import 'fridgenie_api.dart';
import 'ingredient_matcher.dart';

/// Turns a fridge photo into catalog ingredients; the scan screen depends
/// only on this interface, so mock and real scanning are interchangeable.
abstract class IngredientRecognizer {
  /// True when a real AI looks at the photo ("AI Vision" vs "Demo mode").
  bool get isReal;

  /// Provider name shown in the scan-screen subtitle.
  String get displayName;

  /// Detects ingredients in [imageBytes]; [excludeIds] lets the mock prefer
  /// items the user doesn't have yet. Throws [RecognizerException].
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  });
}

/// Picks the real recognizer when the backend is configured, else the mock.
IngredientRecognizer createDefaultRecognizer(FridgenieApi? api) =>
    api == null ? MockIngredientRecognizer() : BackendIngredientRecognizer(api);

/// Offline recognizer returning plausible random detections.
class MockIngredientRecognizer implements IngredientRecognizer {
  MockIngredientRecognizer({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  static const _pool = <String>[
    'tomato', 'eggs', 'cheese', 'onion', 'garlic', 'spinach',
    'bell_pepper', 'carrot', 'mushroom', 'avocado', 'lemon',
    'chicken', 'salmon', 'tuna', 'tofu', 'chickpeas',
    'milk', 'yogurt', 'butter', 'cream', 'feta',
    'rice', 'pasta', 'bread', 'tortilla',
    'olive_oil', 'tomato_sauce', 'beans',
    'basil', 'parsley', 'chili', 'ginger',
  ];

  @override
  bool get isReal => false;

  @override
  String get displayName => 'Demo';

  @override
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 1600));

    final candidates =
        _pool.map(MockIngredients.byId).whereType<Ingredient>().toList();

    // Prefer ingredients the user doesn't already have so each scan feels new.
    final fresh = candidates.where((i) => !excludeIds.contains(i.id)).toList()
      ..shuffle(_rng);
    final stale = candidates.where((i) => excludeIds.contains(i.id)).toList()
      ..shuffle(_rng);

    final count = 4 + _rng.nextInt(3);
    return [...fresh, ...stale].take(count).toList();
  }
}

/// Real recognizer: sends the photo to the Worker, maps names to the catalog.
class BackendIngredientRecognizer implements IngredientRecognizer {
  BackendIngredientRecognizer(this._api, {IngredientMatcher? matcher})
      : _matcher = matcher ?? IngredientMatcher();

  final FridgenieApi _api;
  final IngredientMatcher _matcher;

  @override
  bool get isReal => true;

  @override
  String get displayName => 'Gemini Vision';

  @override
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  }) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      throw const RecognizerException('No image provided. Take a photo first.');
    }

    try {
      final names = await _api.scanIngredients(imageBytes);
      final result = _matcher.matchAll(names);
      debugPrint('[IngredientRecognizer] detected ${names.length}, '
          'matched ${result.matched.length}, unmatched ${result.unmatched}');
      return result.matched;
    } on FridgenieApiException catch (e) {
      throw RecognizerException(e.userMessage);
    }
  }
}

/// Recoverable scan error with a message safe to show to the user.
class RecognizerException implements Exception {
  final String message;
  const RecognizerException(this.message);

  @override
  String toString() => message;
}
