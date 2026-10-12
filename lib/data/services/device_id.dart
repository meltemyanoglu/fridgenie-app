import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Anonymous per-install id sent as `X-Device-Id` so the Worker can rate-limit
/// per phone; it carries no personal data.
class DeviceId {
  DeviceId._();

  static const _key = 'fridgenie.device_id';

  /// Returns the stored id, creating and saving a random one on first launch.
  static Future<String> loadOrCreate(SharedPreferences prefs) async {
    final existing = prefs.getString(_key);
    if (existing != null && existing.length == 32) return existing;

    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString(_key, id);
    return id;
  }
}
