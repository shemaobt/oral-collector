import 'package:flutter/foundation.dart';

enum ForegroundServiceOwner { none, recording, upload }

/// Serializes ownership of the single foreground service shared by recording
/// and upload, so one feature never stops or updates the other's notification.
class ForegroundServiceArbiter {
  ForegroundServiceArbiter._();

  static ForegroundServiceOwner _owner = ForegroundServiceOwner.none;
  static Future<void> _queue = Future<void>.value();

  static ForegroundServiceOwner get owner => _owner;

  static bool isOwner(ForegroundServiceOwner owner) => _owner == owner;

  static Future<void> _serialized(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  static Future<void> takeOver({
    required ForegroundServiceOwner owner,
    required Future<bool> Function() isRunning,
    required Future<void> Function() stop,
    required Future<void> Function() start,
  }) {
    return _serialized(() async {
      if (await isRunning()) {
        await stop();
      }
      await start();
      _owner = owner;
    });
  }

  static Future<void> release({
    required ForegroundServiceOwner owner,
    required Future<bool> Function() isRunning,
    required Future<void> Function() stop,
  }) {
    return _serialized(() async {
      if (_owner != owner) return;
      if (await isRunning()) {
        await stop();
      }
      _owner = ForegroundServiceOwner.none;
    });
  }

  @visibleForTesting
  static void resetForTest() {
    _owner = ForegroundServiceOwner.none;
    _queue = Future<void>.value();
  }
}
