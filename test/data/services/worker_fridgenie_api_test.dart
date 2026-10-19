import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/services/fridgenie_api.dart';
import 'package:fridgenie/data/services/worker_fridgenie_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

  WorkerFridgenieApi apiWith(MockClientHandler handler, {Duration? timeout}) =>
      WorkerFridgenieApi(
        baseUri: Uri.parse('https://api.test'),
        appToken: 'token-1',
        deviceId: 'device_abcdef12',
        client: MockClient(handler),
        timeout: timeout ?? const Duration(seconds: 5),
      );

  http.Response json(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'x-request-id': 'req-42',
        },
      );

  Future<FridgenieApiException> failureOf(Future<Object?> call) async {
    try {
      await call;
    } on FridgenieApiException catch (e) {
      return e;
    }
    fail('Expected a FridgenieApiException');
  }

  test('scan sends auth headers, base64 image and sniffed mime type', () async {
    late http.Request sent;
    final api = apiWith((request) async {
      sent = request;
      return json({
        'ingredients': ['tomato', 'milk'],
      }, 200);
    });

    final names = await api.scanIngredients(pngBytes);

    expect(names, ['tomato', 'milk']);
    expect(sent.url.toString(), 'https://api.test/v1/scan');
    expect(sent.headers['X-Fridgenie-Token'], 'token-1');
    expect(sent.headers['X-Device-Id'], 'device_abcdef12');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['mimeType'], 'image/png');
    expect(base64Decode(body['imageBase64'] as String), pngBytes);
  });

  test('recipes sends the request contract and maps recipes', () async {
    late Map<String, dynamic> body;
    final api = apiWith((request) async {
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return json({
        'recipes': [
          {
            'title': 'Menemen',
            'ingredients': ['eggs', 'tomato'],
            'steps': [
              {'order': 1, 'text': 'Cook.'},
            ],
          },
        ],
      }, 200);
    });

    final recipes = await api.generateRecipes(const RecipeRequest(
      ingredientNames: ['eggs', 'tomato'],
      mode: GenieMode.healthyQuick,
      dietary: {DietaryPreference.vegetarian},
      cuisine: CuisineType.turkish,
    ));

    expect(body['mode'], 'healthyQuick');
    expect(body['dietary'], ['vegetarian']);
    expect(body['cuisine'], 'turkish');
    expect(body.containsKey('mood'), isFalse);
    expect(recipes.single.title, 'Menemen');
    expect(recipes.single.requiredIngredientIds, ['eggs', 'tomato']);
  });

  test('maps Worker error codes and keeps the request id', () async {
    final api = apiWith((_) async => json({
          'error': {
            'code': 'RATE_LIMITED',
            'message': 'Too many requests.',
            'retryable': true,
          },
          'requestId': 'req-42',
        }, 429));

    final error = await failureOf(api.scanIngredients(pngBytes));

    expect(error.code, FridgenieErrorCode.rateLimited);
    expect(error.retryable, isTrue);
    expect(error.requestId, 'req-42');
    expect(error.userMessage, contains('Try again in a minute'));
  });

  test('maps QUOTA_EXCEEDED to its own daily-limit message', () async {
    final api = apiWith((_) async => json({
          'error': {
            'code': 'QUOTA_EXCEEDED',
            'message': 'Daily limit reached.',
            'retryable': true,
          },
        }, 429));

    final error = await failureOf(api.scanIngredients(pngBytes));

    expect(error.code, FridgenieErrorCode.quotaExceeded);
    expect(error.userMessage, contains('tomorrow'));
  });

  test('falls back to HTTP status when the body is not our JSON', () async {
    final api = apiWith((_) async => http.Response('<html>oops</html>', 502));
    final error = await failureOf(api.scanIngredients(pngBytes));
    expect(error.code, FridgenieErrorCode.aiUnavailable);
    expect(error.retryable, isTrue);
  });

  test('treats an empty recipe list as a bad AI response', () async {
    final api = apiWith((_) async => json({'recipes': []}, 200));
    final error = await failureOf(api.generateRecipes(
      const RecipeRequest(ingredientNames: ['eggs']),
    ));
    expect(error.code, FridgenieErrorCode.aiBadResponse);
  });

  test('reports network failures and timeouts', () async {
    final offline = apiWith((_) async => throw http.ClientException('down'));
    expect((await failureOf(offline.scanIngredients(pngBytes))).code,
        FridgenieErrorCode.network);

    final slow = apiWith(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );
    expect((await failureOf(slow.scanIngredients(pngBytes))).code,
        FridgenieErrorCode.timeout);
  });
}
