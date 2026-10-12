import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/recipe.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/data/storage/storage_keys.dart';
import 'package:fridgenie/data/storage/store_migrations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final mockRecipe = MockRecipes.all.first;
  final aiRecipe = mockRecipe.toJson()
    ..['id'] = 'gen_1'
    ..['title'] = 'AI Special';

  test('v1 favorite ids become full recipe snapshots', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.legacyFavorites: [mockRecipe.id, 'gen_1', 'gone_forever'],
      StorageKeys.legacyFavoriteTitles: '{"gen_1": "AI Special"}',
      StorageKeys.generatedRecipes: jsonEncode([aiRecipe]),
    });
    final store = await LocalStore.open();

    StoreMigrations.run(store);

    final favorites =
        store.readJsonList(StorageKeys.favoriteRecipes, Recipe.fromJson);
    expect(favorites.map((r) => r.id), [mockRecipe.id, 'gen_1']);
    expect(favorites.last.title, 'AI Special');
    expect(store.containsKey(StorageKeys.legacyFavorites), isFalse);
    expect(store.containsKey(StorageKeys.legacyFavoriteTitles), isFalse);
    expect(store.getInt(StorageKeys.schemaVersion),
        StoreMigrations.currentVersion);
  });

  test('undated v1 streaks are reset, recipes cooked is kept', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.currentStreak: 9,
      StorageKeys.longestStreak: 12,
      StorageKeys.recipesCooked: 12,
    });
    final store = await LocalStore.open();

    StoreMigrations.run(store);

    expect(store.getInt(StorageKeys.currentStreak), 0);
    expect(store.getInt(StorageKeys.longestStreak), 0);
    expect(store.getInt(StorageKeys.recipesCooked), 12);
  });

  test('a fresh install just records the current version', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();

    StoreMigrations.run(store);

    expect(store.containsKey(StorageKeys.favoriteRecipes), isFalse);
    expect(store.getInt(StorageKeys.schemaVersion),
        StoreMigrations.currentVersion);
  });

  test('running twice changes nothing', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.schemaVersion: StoreMigrations.currentVersion,
      StorageKeys.legacyFavorites: [mockRecipe.id],
    });
    final store = await LocalStore.open();

    StoreMigrations.run(store);

    expect(store.getStringList(StorageKeys.legacyFavorites), [mockRecipe.id]);
  });
}
