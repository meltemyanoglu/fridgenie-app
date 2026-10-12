import 'package:flutter/foundation.dart';

import '../mock/mock_recipes.dart';
import '../models/recipe.dart';
import 'local_store.dart';
import 'storage_keys.dart';

/// Upgrades on-device data step by step; run once at startup before providers.
class StoreMigrations {
  StoreMigrations._();

  static const _tag = '[StoreMigrations]';

  /// Latest schema; bump it and add a `_toVersionN` step when data changes.
  static const currentVersion = 2;

  static void run(LocalStore store) {
    final version = store.getInt(StorageKeys.schemaVersion) ?? 1;
    if (version >= currentVersion) return;

    debugPrint('$_tag upgrading storage from v$version to v$currentVersion');
    if (version < 2) _toVersion2(store);
    store.setInt(StorageKeys.schemaVersion, currentVersion);
  }

  /// v1 stored favorite ids only, so favorites of old AI recipes got lost once
  /// the 50-recipe cap dropped them. v2 stores full recipe snapshots.
  static void _toVersion2(LocalStore store) {
    final legacyIds = store.getStringList(StorageKeys.legacyFavorites) ?? [];
    if (legacyIds.isNotEmpty) {
      final generated = store.readJsonList(
        StorageKeys.generatedRecipes,
        Recipe.fromJson,
      );
      final known = {
        for (final recipe in [...MockRecipes.all, ...generated])
          recipe.id: recipe,
      };

      final snapshots = legacyIds
          .map((id) => known[id])
          .whereType<Recipe>()
          .map((recipe) => recipe.toJson())
          .toList();
      store.setJson(StorageKeys.favoriteRecipes, snapshots);
      debugPrint('$_tag migrated ${snapshots.length}/${legacyIds.length} '
          'favorites (unresolvable ones were already lost in v1)');
    }

    store.remove(StorageKeys.legacyFavorites);
    store.remove(StorageKeys.legacyFavoriteTitles);
  }
}
