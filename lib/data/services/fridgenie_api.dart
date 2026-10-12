import 'dart:typed_data';

import '../models/enums.dart';
import '../models/recipe.dart';

/// Contract for every AI call the app makes; the real impl talks to the Worker.
abstract interface class FridgenieApi {
  /// Returns plain ingredient names detected in a fridge photo.
  Future<List<String>> scanIngredients(Uint8List imageBytes);

  /// Returns 1..4 recipes; never empty, throws [FridgenieApiException] instead.
  Future<List<Recipe>> generateRecipes(RecipeRequest request);

  /// Releases the underlying HTTP client.
  void close();
}

/// Everything the AI chef needs to invent recipes for this user.
class RecipeRequest {
  /// Plain ingredient names (not catalog ids).
  final List<String> ingredientNames;
  final GenieMode mode;
  final int count;
  final Set<DietaryPreference> dietary;
  final Mood? mood;
  final CuisineType? cuisine;
  final CookingSkill? skill;
  final List<String> avoidTitles;

  const RecipeRequest({
    required this.ingredientNames,
    this.mode = GenieMode.standard,
    this.count = 1,
    this.dietary = const {},
    this.mood,
    this.cuisine,
    this.skill,
    this.avoidTitles = const [],
  });

  /// JSON body for `POST /v1/recipes`; enum `.name` values match the Worker.
  Map<String, dynamic> toJson() => {
        'ingredients': ingredientNames,
        'mode': mode.name,
        'count': count,
        'dietary': dietary.map((d) => d.name).toList(),
        if (mood != null) 'mood': mood!.name,
        if (cuisine != null) 'cuisine': cuisine!.name,
        if (skill != null) 'skill': skill!.name,
        'avoidTitles': avoidTitles,
      };
}

/// Error categories; Worker codes map 1:1, plus client-side network failures.
enum FridgenieErrorCode {
  badRequest,
  unauthorized,
  payloadTooLarge,
  unsupportedMediaType,
  rateLimited,
  aiUnavailable,
  aiBadResponse,
  serverMisconfigured,
  network,
  timeout,
  unknown;

  /// Maps a Worker `error.code` string such as `RATE_LIMITED`.
  static FridgenieErrorCode fromWire(String? code) => switch (code) {
        'BAD_REQUEST' => badRequest,
        'UNAUTHORIZED' => unauthorized,
        'PAYLOAD_TOO_LARGE' => payloadTooLarge,
        'UNSUPPORTED_MEDIA_TYPE' => unsupportedMediaType,
        'RATE_LIMITED' => rateLimited,
        'AI_UNAVAILABLE' => aiUnavailable,
        'AI_BAD_RESPONSE' => aiBadResponse,
        'SERVER_MISCONFIGURED' => serverMisconfigured,
        _ => unknown,
      };
}

/// Failure from the AI backend; [userMessage] is safe to show on screen.
class FridgenieApiException implements Exception {
  final FridgenieErrorCode code;

  /// Developer-facing detail for logs.
  final String message;
  final bool retryable;
  final int? statusCode;

  /// Worker request id, to find this call in `wrangler tail` logs.
  final String? requestId;

  const FridgenieApiException(
    this.code,
    this.message, {
    this.retryable = false,
    this.statusCode,
    this.requestId,
  });

  String get userMessage => switch (code) {
        FridgenieErrorCode.rateLimited =>
          'Genie needs a short break. Try again in a minute.',
        FridgenieErrorCode.network =>
          'No connection to Genie. Check your internet and try again.',
        FridgenieErrorCode.timeout =>
          'Genie is taking too long. Please try again.',
        FridgenieErrorCode.payloadTooLarge =>
          'That photo is too big. Try a smaller one.',
        FridgenieErrorCode.unsupportedMediaType =>
          'That image format is not supported. Try a JPEG or PNG.',
        FridgenieErrorCode.aiUnavailable ||
        FridgenieErrorCode.aiBadResponse =>
          'Genie is having a moment. Please try again.',
        _ => 'Something went wrong with Genie. Please try again later.',
      };

  @override
  String toString() =>
      'FridgenieApiException($code, status: $statusCode, '
      'requestId: $requestId): $message';
}
