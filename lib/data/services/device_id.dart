import 'dart:math';

import '../storage/local_store.dart';
import '../storage/storage_keys.dart';

/// Anonymous per-install id sent as `X-Device-Id` so the Worker can rate-limit
/// per phone; it carries no personal data.
class DeviceId {
  DeviceId._();

  /// Returns the stored id, creating and saving a random one on first launch.
  static String loadOrCreate(LocalStore store) {
    final existing = store.getString(StorageKeys.deviceId);
    if (existing != null && existing.length == 32) return existing;

    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    store.setString(StorageKeys.deviceId, id);
    return id;
  }
}
