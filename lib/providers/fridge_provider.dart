import 'package:flutter/foundation.dart';

import '../data/mock/mock_ingredients.dart';
import '../data/models/enums.dart';
import '../data/models/ingredient.dart';
import '../data/storage/local_store.dart';
import '../data/storage/storage_keys.dart';

/// What's in the fridge (inventory) and what the user picked to cook with.
/// Removing an item from the fridge also unselects it.
class FridgeProvider extends ChangeNotifier {
  FridgeProvider(this._store) {
    final inventory = _store.getStringList(StorageKeys.inventory);
    // First launch gets a starter fridge; an empty saved list stays empty.
    _inventoryIds.addAll(inventory ?? _defaultInventory);
    // Selection is independent of inventory: the home grid offers any
    // common ingredient, so restoring must not drop those picks.
    final selected = _store.getStringList(StorageKeys.selected);
    _selectedIds.addAll(selected ?? const <String>[]);
    debugPrint('[FridgeProvider] loaded ${_inventoryIds.length} items, '
        '${_selectedIds.length} selected');
  }

  static const _defaultInventory = {
    'eggs', 'tomato', 'cheese', 'onion', 'rice', 'olive_oil', 'garlic',
    'spinach',
  };

  final LocalStore _store;
  final Set<String> _inventoryIds = {};
  final Set<String> _selectedIds = {};

  Set<String> get inventoryIds => Set.unmodifiable(_inventoryIds);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  List<Ingredient> get inventory =>
      _inventoryIds.map(MockIngredients.byId).whereType<Ingredient>().toList();

  List<Ingredient> get selected =>
      _selectedIds.map(MockIngredients.byId).whereType<Ingredient>().toList();

  List<Ingredient> ingredientsByCategory(IngredientCategory cat) =>
      inventory.where((i) => i.category == cat).toList();

  bool isInInventory(String id) => _inventoryIds.contains(id);
  bool isSelected(String id) => _selectedIds.contains(id);

  void toggleInventory(String id) {
    if (!_inventoryIds.remove(id)) {
      _inventoryIds.add(id);
    } else {
      _selectedIds.remove(id);
    }
    _commit();
  }

  void toggleSelected(String id) {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    _commit();
  }

  void clearSelected() {
    _selectedIds.clear();
    _commit();
  }

  void selectAll() {
    _selectedIds.addAll(_inventoryIds);
    _commit();
  }

  void addManyToInventory(Iterable<String> ids) {
    _inventoryIds.addAll(ids);
    _commit();
  }

  void addManyToSelection(Iterable<String> ids) {
    _selectedIds.addAll(ids);
    _commit();
  }

  /// Saves both sets and notifies; every mutation goes through here.
  void _commit() {
    _store.setStringList(StorageKeys.inventory, _inventoryIds.toList());
    _store.setStringList(StorageKeys.selected, _selectedIds.toList());
    notifyListeners();
  }
}
