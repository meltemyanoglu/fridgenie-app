import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/grocery_item.dart';

class GroceryProvider extends ChangeNotifier {
  static const _kKey = 'fridgenie.grocery_list';

  final List<GroceryItem> _items = [];
  final Map<String, Timer> _deleteTimers = {};

  // Completer ensures _prefs is always ready before any write.
  final Completer<SharedPreferences> _ready = Completer();

  GroceryProvider() {
    _load();
  }

  List<GroceryItem> get items => List.unmodifiable(_items);
  List<GroceryItem> get unchecked => _items.where((i) => !i.isChecked).toList();
  List<GroceryItem> get checked => _items.where((i) => i.isChecked).toList();
  int get totalCount => _items.length;
  int get checkedCount => checked.length;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ready.complete(prefs);
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        _items.addAll(GroceryItem.listFromJson(raw));
      } catch (_) {}
    }
    notifyListeners();
  }

  // Fire-and-forget — always waits for prefs to be ready.
  void _save() {
    _ready.future.then(
      (prefs) => prefs.setString(_kKey, GroceryItem.listToJson(_items)),
    );
  }

  bool contains(String name) =>
      _items.any((i) => i.name.trim().toLowerCase() == name.trim().toLowerCase());

  void addItem(String name, String emoji) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || contains(trimmed)) return;
    _items.add(GroceryItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${trimmed.hashCode}',
      name: trimmed,
      emoji: emoji,
    ));
    _save();
    notifyListeners();
  }

  void toggleItem(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx].isChecked = !_items[idx].isChecked;
    if (_items[idx].isChecked) {
      _deleteTimers[id]?.cancel();
      _deleteTimers[id] = Timer(const Duration(seconds: 5), () => removeItem(id));
    } else {
      _deleteTimers[id]?.cancel();
      _deleteTimers.remove(id);
    }
    _save();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _save();
    notifyListeners();
  }

  void clearChecked() {
    _items.removeWhere((i) => i.isChecked);
    _save();
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _save();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _deleteTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}
