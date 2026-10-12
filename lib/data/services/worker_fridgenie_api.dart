import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'fridgenie_api.dart';
import 'recipe_mapper.dart';

/// [FridgenieApi] backed by the Cloudflare Worker (see `worker/README.md`).
class WorkerFridgenieApi implements FridgenieApi {
  WorkerFridgenieApi({
    required Uri baseUri,
    required String appToken,
    required String deviceId,
    http.Client? client,
    RecipeMapper? mapper,
    this.timeout = const Duration(seconds: 60),
  })  : _baseUri = baseUri.path.endsWith('/')
            ? baseUri
            : baseUri.replace(path: '${baseUri.path}/'),
        _headers = {
          'Content-Type': 'application/json',
          'X-Fridgenie-Token': appToken,
          'X-Device-Id': deviceId,
        },
        _client = client ?? http.Client(),
        _mapper = mapper ?? RecipeMapper();

  static const _tag = '[FridgenieApi]';

  final Uri _baseUri;
  final Map<String, String> _headers;
  final http.Client _client;
  final RecipeMapper _mapper;

  /// Client-side limit; above the Worker's own 25 s timeout plus one retry.
  final Duration timeout;

  @override
  Future<List<String>> scanIngredients(Uint8List imageBytes) async {
    final body = await _post('v1/scan', {
      'imageBase64': base64Encode(imageBytes),
      'mimeType': _sniffMimeType(imageBytes),
    });
    final names = (body['ingredients'] as List?)?.whereType<String>().toList();
    return names ?? const [];
  }

  @override
  Future<List<Recipe>> generateRecipes(RecipeRequest request) async {
    final body = await _post('v1/recipes', request.toJson());
    final recipes = (body['recipes'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_mapper.fromJson)
        .toList();

    if (recipes.isEmpty) {
      throw const FridgenieApiException(
        FridgenieErrorCode.aiBadResponse,
        'Worker returned no recipes.',
        retryable: true,
      );
    }
    return recipes;
  }

  @override
  void close() => _client.close();

  /// POSTs JSON and returns the decoded body; throws [FridgenieApiException].
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = _baseUri.resolve(path);
    final stopwatch = Stopwatch()..start();
    http.Response response;

    try {
      response = await _client
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(timeout);
    } on TimeoutException {
      debugPrint('$_tag POST $path timed out after ${timeout.inSeconds}s');
      throw const FridgenieApiException(
        FridgenieErrorCode.timeout,
        'Request timed out.',
        retryable: true,
      );
    } on http.ClientException catch (error) {
      debugPrint('$_tag POST $path network error: $error');
      throw FridgenieApiException(
        FridgenieErrorCode.network,
        'Network error: $error',
        retryable: true,
      );
    } catch (error, stack) {
      debugPrint('$_tag POST $path unexpected error: $error\n$stack');
      throw FridgenieApiException(
        FridgenieErrorCode.unknown,
        'Unexpected error: $error',
      );
    }

    final requestId = response.headers['x-request-id'];
    debugPrint('$_tag POST $path -> ${response.statusCode} '
        'in ${stopwatch.elapsedMilliseconds}ms (requestId: $requestId)');

    // Decode bytes as UTF-8 ourselves so emoji survive a missing charset.
    final decoded =
        _decode(utf8.decode(response.bodyBytes, allowMalformed: true));
    if (response.statusCode == 200 && decoded != null) return decoded;
    throw _toException(response.statusCode, decoded, requestId);
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static FridgenieApiException _toException(
    int status,
    Map<String, dynamic>? body,
    String? requestId,
  ) {
    final error = body?['error'];
    final details = error is Map ? error : const {};
    final code = details['code'];
    final message = details['message'];
    final retryable =
        details['retryable'] == true || status == 429 || status >= 500;
    final wireCode = FridgenieErrorCode.fromWire(code is String ? code : null);
    final exception = FridgenieApiException(
      wireCode != FridgenieErrorCode.unknown
          ? wireCode
          : _codeForStatus(status),
      message is String ? message : 'HTTP $status with an unexpected body.',
      retryable: retryable,
      statusCode: status,
      requestId: requestId,
    );
    debugPrint('$_tag $exception');
    return exception;
  }

  /// Fallback when the body has no known error code (e.g. a proxy HTML page).
  static FridgenieErrorCode _codeForStatus(int status) => switch (status) {
        200 => FridgenieErrorCode.aiBadResponse,
        401 || 403 => FridgenieErrorCode.unauthorized,
        413 => FridgenieErrorCode.payloadTooLarge,
        429 => FridgenieErrorCode.rateLimited,
        >= 500 => FridgenieErrorCode.aiUnavailable,
        _ => FridgenieErrorCode.unknown,
      };

  /// Detects PNG/WebP from magic bytes; everything else is sent as JPEG.
  static String _sniffMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
