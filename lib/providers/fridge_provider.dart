import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock/mock_ingredients.dart';
import '../data/models/enums.dart';
import '../data/models/ingredient.dart';

class FridgeProvider extends ChangeNotifier {
  static const _kInventoryKey = 'fridgenie.inventory';
  static const _kSelectedKey = 'fridgenie.selected';

  static const _defaultInventory = {
    'eggs', 'tomato', 'cheese', 'onion', 'rice', 'olive_oil', 'garlic', 'spinach',
  };

  final Set<String> _inventoryIds = {};
  final Set<String> _selectedIds = {};
  SharedPreferences? _prefs;

  FridgeProvider() {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final inv = _prefs!.getStringList(_kInventoryKey);
    final sel = _prefs!.getStringList(_kSelectedKey);

    if (inv == null) {
      // First launch — use defaults
      _inventoryIds.addAll(_defaultInventory);
    } else {
      _inventoryIds.addAll(inv);
    }

    if (sel != null) {
      // Only restore selected IDs that are still in inventory
      _selectedIds.addAll(sel.where(_inventoryIds.contains));
    }

    notifyListeners();
  }

  void _saveInventory() =>
      _prefs?.setStringList(_kInventoryKey, _inventoryIds.toList());

  void _saveSelected() =>
      _prefs?.setStringList(_kSelectedKey, _selectedIds.toList());

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
    if (_inventoryIds.contains(id)) {
      _inventoryIds.remove(id);
      _selectedIds.remove(id);
    } else {
      _inventoryIds.add(id);
    }
    _saveInventory();
    _saveSelected();
    notifyListeners();
  }

  void toggleSelected(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    _saveSelected();
    notifyListeners();
  }

  void clearSelected() {
    _selectedIds.clear();
    _saveSelected();
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_inventoryIds);
    _saveSelected();
    notifyListeners();
  }

  void addManyToInventory(Iterable<String> ids) {
    _inventoryIds.addAll(ids);
    _saveInventory();
    notifyListeners();
  }

  void addManyToSelection(Iterable<String> ids) {
    _selectedIds.addAll(ids);
    _saveSelected();
    notifyListeners();
  }
}
