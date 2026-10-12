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

  /// v1 stored favorite ids only (lost after the 50-recipe cap) and counted a
  /// streak +1 per cook with no dates. v2 stores full recipes and day streaks.
  static void _toVersion2(LocalStore store) {
    _resetUndatedStreak(store);

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

  /// v1 streaks have no dates and were inflated by repeated taps, so they
  /// can't be trusted; recipes cooked stays as the honest lifetime count.
  static void _resetUndatedStreak(LocalStore store) {
    if (store.containsKey(StorageKeys.lastCookedOn)) return;
    final current = store.getInt(StorageKeys.currentStreak) ?? 0;
    final longest = store.getInt(StorageKeys.longestStreak) ?? 0;
    if (current == 0 && longest == 0) return;

    store.setInt(StorageKeys.currentStreak, 0);
    store.setInt(StorageKeys.longestStreak, 0);
    debugPrint('$_tag reset undated v1 streak (current $current, '
        'longest $longest)');
  }
}
