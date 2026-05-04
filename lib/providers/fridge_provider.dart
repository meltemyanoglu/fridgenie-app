import 'package:flutter/foundation.dart';

import '../data/mock/mock_ingredients.dart';
import '../data/models/enums.dart';
import '../data/models/ingredient.dart';

class FridgeProvider extends ChangeNotifier {
  /// Persistent inventory — what the user has at home.
  final Set<String> _inventoryIds = {
    'eggs',
    'tomato',
    'cheese',
    'onion',
    'rice',
    'olive_oil',
    'garlic',
    'spinach',
  };

  /// Active selection — what the user is currently cooking with.
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
    if (_inventoryIds.contains(id)) {
      _inventoryIds.remove(id);
      _selectedIds.remove(id);
    } else {
      _inventoryIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelected(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedIds.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_inventoryIds);
    notifyListeners();
  }

  void addManyToInventory(Iterable<String> ids) {
    _inventoryIds.addAll(ids);
    notifyListeners();
  }

  void addManyToSelection(Iterable<String> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }
}
