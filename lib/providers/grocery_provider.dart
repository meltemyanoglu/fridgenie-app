import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/grocery_item.dart';
import '../data/storage/local_store.dart';
import '../data/storage/storage_keys.dart';

/// Shopping list; checked items vanish after [checkedLifetime].
class GroceryProvider extends ChangeNotifier {
  GroceryProvider(
    this._store, {
    this.checkedLifetime = const Duration(seconds: 5),
  }) {
    _items.addAll(
      _store.readJsonList(StorageKeys.groceryList, GroceryItem.fromJson),
    );
    // Items checked before the app closed would never get their timer back.
    _items.removeWhere((item) => item.isChecked);
    debugPrint('[GroceryProvider] loaded ${_items.length} items');
  }

  final LocalStore _store;

  /// How long a checked item stays visible (so a mis-tap can be undone).
  final Duration checkedLifetime;

  final List<GroceryItem> _items = [];
  final Map<String, Timer> _removalTimers = {};
  int _idCounter = 0;

  List<GroceryItem> get items => List.unmodifiable(_items);
  List<GroceryItem> get unchecked =>
      _items.where((i) => !i.isChecked).toList();
  List<GroceryItem> get checked => _items.where((i) => i.isChecked).toList();
  int get totalCount => _items.length;
  int get checkedCount => checked.length;

  bool contains(String name) {
    final key = name.trim().toLowerCase();
    return _items.any((i) => i.name.trim().toLowerCase() == key);
  }

  void addItem(String name, String emoji) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || contains(trimmed)) return;
    _items.add(GroceryItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      name: trimmed,
      emoji: emoji,
    ));
    _commit();
  }

  void toggleItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _items[index].copyWith(isChecked: !_items[index].isChecked);
    _items[index] = item;
    _cancelTimer(id);
    if (item.isChecked) {
      _removalTimers[id] = Timer(checkedLifetime, () => removeItem(id));
    }
    _commit();
  }

  void removeItem(String id) {
    _cancelTimer(id);
    final before = _items.length;
    _items.removeWhere((i) => i.id == id);
    if (_items.length != before) _commit();
  }

  void clearChecked() {
    for (final item in checked) {
      _cancelTimer(item.id);
    }
    _items.removeWhere((i) => i.isChecked);
    _commit();
  }

  void clearAll() {
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
    _items.clear();
    _commit();
  }

  void _cancelTimer(String id) => _removalTimers.remove(id)?.cancel();

  /// Saves and notifies; every mutation goes through here.
  void _commit() {
    _store.setJson(
      StorageKeys.groceryList,
      _items.map((i) => i.toJson()).toList(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
    super.dispose();
  }
}
