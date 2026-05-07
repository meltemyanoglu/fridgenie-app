import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../mock/mock_ingredients.dart';
import '../models/ingredient.dart';

/// Strategy for turning a fridge photo into a list of detected ingredients.
///
/// We keep this abstract so the UI doesn't care whether the answer comes from
/// a mock (offline / no API key) or a real cloud vision model. Swap the impl
/// at the app boundary and everything else just works.
abstract class IngredientRecognizer {
  /// True if this recognizer makes a real API call. The UI uses this to label
  /// the experience honestly ("AI Vision" vs. "Demo mode").
  bool get isReal;

  /// Short, human-readable provider name shown in the scan-screen subtitle
  /// (e.g. "Gemini Vision", "GPT-4 Vision", "Demo").
  String get displayName;

  /// Detect ingredients visible in [imageBytes]. [excludeIds] lets the caller
  /// hint that the user already has those items, so the recognizer can prefer
  /// new findings (mock impl uses this; real impls may ignore it).
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  });
}

/// Hardcoded fallback for the Cloudflare Worker URL — once you've deployed
/// `worker/`, paste your URL here so production builds pick it up without
/// needing a `--dart-define`. Leave empty to require the build flag.
const _kBackendUrl = '';

/// Returns the configured backend URL (dart-define wins, then hardcoded).
/// Empty string means no backend is configured.
String resolveBackendUrl() {
  const backendOverride =
      String.fromEnvironment('FRIDGENIE_BACKEND', defaultValue: '');
  return backendOverride.isNotEmpty ? backendOverride : _kBackendUrl;
}

/// Convenience: pick the right recognizer at app start.
///
/// Priority:
///   1. `--dart-define=FRIDGENIE_BACKEND=https://...`  → BackendVisionRecognizer
///   2. hardcoded `_kBackendUrl`                       → BackendVisionRecognizer
///   3. `--dart-define=OPENAI_API_KEY=sk-...`          → OpenAIVisionRecognizer
///   4. nothing set                                    → MockIngredientRecognizer
IngredientRecognizer createDefaultRecognizer() {
  final backendUrl = resolveBackendUrl();
  if (backendUrl.isNotEmpty) {
    return BackendVisionRecognizer(endpoint: backendUrl);
  }

  const openAiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  if (openAiKey.isNotEmpty) {
    return OpenAIVisionRecognizer(apiKey: openAiKey);
  }

  return MockIngredientRecognizer();
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock implementation — no network, deterministic-ish results.
// ─────────────────────────────────────────────────────────────────────────────

class MockIngredientRecognizer implements IngredientRecognizer {
  final Random _rng;
  MockIngredientRecognizer({Random? rng}) : _rng = rng ?? Random();

  @override
  bool get isReal => false;

  @override
  String get displayName => 'Demo';

  @override
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  }) async {
    // Pretend we're "looking" for a moment.
    await Future.delayed(const Duration(milliseconds: 1600));

    // A wide pool of plausible detections — kept here (and not in the API
    // impl) because it's the fallback brain.
    final pool = <String>[
      'tomato', 'eggs', 'cheese', 'onion', 'garlic', 'spinach',
      'bell_pepper', 'carrot', 'mushroom', 'avocado', 'lemon',
      'chicken', 'salmon', 'tuna', 'tofu', 'chickpeas',
      'milk', 'yogurt', 'butter', 'cream', 'feta',
      'rice', 'pasta', 'bread', 'tortilla',
      'olive_oil', 'tomato_sauce', 'beans',
      'basil', 'parsley', 'chili', 'ginger',
    ];

    final candidates = pool
        .map(MockIngredients.byId)
        .whereType<Ingredient>()
        .toList();

    // Prefer ingredients the user doesn't already have so each scan feels new.
    final fresh = candidates.where((i) => !excludeIds.contains(i.id)).toList()
      ..shuffle(_rng);
    final stale = candidates.where((i) => excludeIds.contains(i.id)).toList()
      ..shuffle(_rng);

    final ordered = [...fresh, ...stale];
    final count = 4 + _rng.nextInt(3); // 4–6 detections
    return ordered.take(count).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OpenAI GPT-4o Vision implementation — sends a real photo, parses JSON back.
// ─────────────────────────────────────────────────────────────────────────────

class OpenAIVisionRecognizer implements IngredientRecognizer {
  final String apiKey;
  final String model;
  final http.Client _client;

  OpenAIVisionRecognizer({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  bool get isReal => true;

  @override
  String get displayName => 'GPT-4 Vision';

  static const _systemPrompt =
      'You are an ingredient detector for a smart cooking app. Look at the '
      'photo of a fridge or pantry and identify visible food ingredients. '
      'Return ONLY valid JSON in this exact shape, no prose:\n'
      '{"ingredients": ["tomato", "onion", "milk"]}\n'
      'Rules:\n'
      '- Lowercase, singular, simple common names (tomato, not "Roma tomato").\n'
      '- Only edible food / drink items.\n'
      '- Maximum 12 items.\n'
      '- If nothing identifiable, return {"ingredients": []}.';

  @override
  Future<List<Ingredient>> detect({
    Uint8List? imageBytes,
    Set<String> excludeIds = const {},
  }) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      throw const RecognizerException(
        'No image provided. Take a photo first.',
      );
    }

    final base64 = base64Encode(imageBytes);
    final dataUrl = 'data:image/jpeg;base64,$base64';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Identify the food ingredients visible in this photo and return JSON only.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'max_tokens': 300,
      'response_format': {'type': 'json_object'},
    });

    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw RecognizerException('Network error reaching AI: $e');
    }

    if (res.statusCode != 200) {
      throw RecognizerException(
        'AI returned ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 200))}',
      );
    }

    String content;
    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>;
      final message = choices.first['message'] as Map<String, dynamic>;
      content = message['content'] as String;
    } catch (e) {
      throw const RecognizerException('Could not parse AI response.');
    }

    // The model is asked for JSON; pull the ingredient name list out.
    final names = _extractNames(content);

    // Map natural-language names back to our ingredient catalog.
    return _matchNamesToCatalog(names);
  }

  /// Best-effort: extract names from a JSON-ish reply.
  List<String> _extractNames(String content) {
    try {
      final obj = jsonDecode(content);
      if (obj is Map<String, dynamic>) {
        final raw = obj['ingredients'];
        if (raw is List) {
          return raw.whereType<String>().toList();
        }
      }
      if (obj is List) {
        return obj.whereType<String>().toList();
      }
    } catch (_) {
      // Fallback: try to find a JSON object substring.
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final inner = jsonDecode(content.substring(start, end + 1));
          if (inner is Map<String, dynamic>) {
            final raw = inner['ingredients'];
            if (raw is List) return raw.whereType<String>().toList();
          }
        } catch (_) {/* give up */}
      }
    }
    return const [];
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Backend (Cloudflare Worker) implementation — preferred for shipped builds.
//
// The Worker holds the Gemini API key. The app POSTs the photo as base64
// and gets back a clean ingredient list. See `worker/README.md` for setup.
// ─────────────────────────────────────────────────────────────────────────────

class BackendVisionRecognizer implements IngredientRecognizer {
  /// Full URL of the deployed Cloudflare Worker, e.g.
  /// `https://fridgenie-vision.you.workers.dev`.
  final String endpoint;
  final http.Client _client;
  final Duration timeout;

  BackendVisionRecognizer({
    required this.endpoint,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

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
      throw const RecognizerException(
        'No image provided. Take a photo first.',
      );
    }

    final base64 = base64Encode(imageBytes);

    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'imageBase64': base64,
              'mimeType': 'image/jpeg',
            }),
          )
          .timeout(timeout);
    } catch (e) {
      throw RecognizerException('Network error reaching backend: $e');
    }

    if (res.statusCode != 200) {
      String detail = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['error'] is String) detail = j['error'] as String;
      } catch (_) {/* keep raw body */}
      throw RecognizerException(
        'Backend returned ${res.statusCode}: $detail',
      );
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw const RecognizerException('Backend returned invalid JSON.');
    }

    final raw = parsed['ingredients'];
    if (raw is! List) return const [];

    final names = raw.whereType<String>().toList();
    return _matchNamesToCatalog(names);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared natural-language → catalog matcher used by both real recognizers.
// ─────────────────────────────────────────────────────────────────────────────

const _synonyms = <String, String>{
  'scallion': 'onion',
  'green onion': 'onion',
  'spring onion': 'onion',
  'courgette': 'zucchini',
  'aubergine': 'eggplant',
  'capsicum': 'bell_pepper',
  'pepper': 'bell_pepper',
  'red pepper': 'bell_pepper',
  'green pepper': 'bell_pepper',
  'cilantro': 'cilantro',
  'coriander': 'cilantro',
  'olive oil': 'olive_oil',
  'extra virgin olive oil': 'olive_oil',
  'tomato sauce': 'tomato_sauce',
  'pasta sauce': 'tomato_sauce',
  'soy sauce': 'soy_sauce',
  'chili flakes': 'chili',
  'red chili': 'chili',
  'chilli': 'chili',
  'chickpea': 'chickpeas',
  'garbanzo': 'chickpeas',
  'lentil': 'lentils',
  'tomatoes': 'tomato',
  'onions': 'onion',
  'eggs': 'eggs',
  'egg': 'eggs',
  'bananas': 'banana',
  'banana': 'banana',
  'mushrooms': 'mushroom',
  'carrots': 'carrot',
  'potatoes': 'potato',
  'avocados': 'avocado',
  'lemons': 'lemon',
  'limes': 'lime',
};

List<Ingredient> _matchNamesToCatalog(List<String> names) {
  if (names.isEmpty) return const [];

  final results = <Ingredient>{};
  for (final raw in names) {
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) continue;

    // 1. exact synonym hit
    final mappedId = _synonyms[clean];
    if (mappedId != null) {
      final ing = MockIngredients.byId(mappedId);
      if (ing != null) {
        results.add(ing);
        continue;
      }
    }

    // 2. exact id match (snake_case)
    final byId = MockIngredients.byId(clean.replaceAll(' ', '_'));
    if (byId != null) {
      results.add(byId);
      continue;
    }

    // 3. fuzzy contains match against catalog names
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
    if (hit != null) results.add(hit);
  }
  return results.toList();
}

/// Recoverable error surfaced to the UI.
class RecognizerException implements Exception {
  final String message;
  const RecognizerException(this.message);
  @override
  String toString() => message;
}
