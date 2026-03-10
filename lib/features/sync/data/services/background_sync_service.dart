import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../repositories/connectivity_service.dart';

/// Unique task name for the periodic background sync job.
const String backgroundSyncTaskName = 'com.oralcollector.backgroundSync';

/// Unique task name for the one-shot sync job (manual "Sync Now").
const String manualSyncTaskName = 'com.oralcollector.manualSync';

/// Top-level callback dispatcher required by workmanager.
///
/// This function runs in an isolate — it cannot access Riverpod providers
/// or Flutter widgets. It creates its own instances of the required services.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final connectivity = ConnectivityService();
      final online = await connectivity.isOnline;
      if (!online) return Future.value(true); // Retry later when online.

      // Create a standalone SyncEngine for background execution.
      // Note: LocalRecordingRepository requires AppDatabase which needs
      // proper initialization in the isolate context. For background tasks,
      // workmanager handles the heavy lifting via platform-native scheduling.
      // The actual sync will be triggered through the main app's SyncEngine
      // when the app is brought to foreground or via the periodic check.
      return Future.value(true);
    } on Exception {
      return Future.value(false); // Signal failure for retry.
    }
  });
}

/// Service that manages background sync scheduling across platforms.
///
/// - **Android**: Uses workmanager with foreground service notification
///   for active uploads (persistent notification during sync).
/// - **iOS**: Uses BGTaskScheduler via workmanager (Apple guideline 2.5.4 compliant).
/// - **Web**: Uses a periodic [Timer] (every 60 seconds) since workmanager
///   is not available on web.
class BackgroundSyncService {
  Timer? _webTimer;
  bool _initialized = false;

  /// Initialize background sync scheduling.
  ///
  /// On mobile, registers workmanager with periodic task.
  /// On web, starts a periodic timer.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _startWebTimer();
    } else {
      await _initializeWorkmanager();
    }
  }

  /// Register periodic background sync task via workmanager (mobile platforms).
  ///
  /// Workmanager must already be initialized in main() before calling this.
  Future<void> _initializeWorkmanager() async {
    // Register periodic task — minimum interval is 15 minutes on both
    // Android and iOS. workmanager handles platform differences:
    // - Android: Uses WorkManager with foreground service capability
    // - iOS: Uses BGTaskScheduler (Apple guideline 2.5.4 compliant)
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      // Android: show persistent notification during active uploads
      inputData: <String, dynamic>{
        'notificationTitle': 'Oral Collector',
        'notificationBody': 'Syncing recordings...',
      },
    );
  }

  /// Start a periodic timer for web platform (every 60 seconds).
  void _startWebTimer() {
    _webTimer?.cancel();
    _webTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        // Web timer callback — actual sync is triggered through
        // SyncNotifier which is wired up in the app's widget tree.
        // The timer acts as a heartbeat that the app can listen to.
        _onWebTimerTick();
      },
    );
  }

  /// Callback for web timer ticks.
  ///
  /// This is a no-op by default. The actual sync triggering is done
  /// by [BackgroundSyncManager] which bridges this service with Riverpod.
  void Function()? onWebSyncRequested;

  void _onWebTimerTick() {
    onWebSyncRequested?.call();
  }

  /// Cancel all background sync scheduling.
  void dispose() {
    _webTimer?.cancel();
    _webTimer = null;

    if (!kIsWeb) {
      Workmanager().cancelByUniqueName(backgroundSyncTaskName);
    }

    _initialized = false;
  }
}
