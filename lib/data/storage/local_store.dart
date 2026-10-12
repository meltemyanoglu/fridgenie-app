import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synchronous key-value store opened once before `runApp`, so providers can
/// load in their constructor and no write is ever dropped while loading.
class LocalStore {
  LocalStore._(this._prefs);

  static const _tag = '[LocalStore]';

  final SharedPreferences _prefs;

  /// Opens the platform store; call once at startup.
  static Future<LocalStore> open() async =>
      LocalStore._(await SharedPreferences.getInstance());

  // ── Reads (served from the in-memory cache) ─────────────────────────────

  bool containsKey(String key) => _prefs.containsKey(key);
  String? getString(String key) => _prefs.getString(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);

  /// Decodes a JSON list item by item; bad items are skipped, not fatal.
  List<T> readJsonList<T>(
    String key,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final decoded = _decode(key);
    if (decoded == null) return [];
    if (decoded is! List) {
      debugPrint('$_tag "$key" is not a JSON list, ignoring it.');
      return [];
    }

    final items = <T>[];
    var skipped = 0;
    for (final item in decoded) {
      try {
        items.add(parse(Map<String, dynamic>.from(item as Map)));
      } catch (e) {
        skipped++;
        debugPrint('$_tag skipped a bad item in "$key": $e');
      }
    }
    if (skipped > 0) {
      debugPrint('$_tag "$key": kept ${items.length}, skipped $skipped');
    }
    return items;
  }

  /// Decodes a JSON object map; returns an empty map on bad data.
  Map<String, dynamic> readJsonMap(String key) {
    final decoded = _decode(key);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  /// Returns the decoded JSON for [key], or null when missing or invalid.
  Object? _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException catch (e) {
      debugPrint('$_tag "$key" is not valid JSON, ignoring it: $e');
      return null;
    }
  }

  // ── Writes (cache updates now, disk write runs in the background) ───────

  void setString(String key, String value) =>
      _write(key, _prefs.setString(key, value));

  void setStringList(String key, List<String> value) =>
      _write(key, _prefs.setStringList(key, value));

  void setInt(String key, int value) => _write(key, _prefs.setInt(key, value));

  void setBool(String key, bool value) =>
      _write(key, _prefs.setBool(key, value));

  void setJson(String key, Object? value) =>
      _write(key, _prefs.setString(key, jsonEncode(value)));

  void remove(String key) => _write(key, _prefs.remove(key));

  /// Logs failed disk writes instead of letting them disappear silently.
  void _write(String key, Future<bool> pending) {
    unawaited(pending.then(
      (ok) {
        if (!ok) debugPrint('$_tag write of "$key" was rejected');
      },
      onError: (Object e) => debugPrint('$_tag write of "$key" failed: $e'),
    ));
  }
}
