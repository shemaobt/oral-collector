import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../repositories/connectivity_service.dart';

const String backgroundSyncTaskName = 'com.oralcollector.backgroundSync';

const String manualSyncTaskName = 'com.oralcollector.manualSync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final connectivity = ConnectivityServiceImpl();
      final online = await connectivity.isOnline;
      if (!online) return Future.value(true);

      return Future.value(true);
    } on Exception {
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  Timer? _webTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _initializeWorkmanager();
      } on Exception {
        _startWebTimer();
      }
    } else {
      _startWebTimer();
    }
  }

  Future<void> _initializeWorkmanager() async {
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: <String, dynamic>{
        'notificationTitle': 'Oral Collector',
        'notificationBody': 'Syncing recordings...',
      },
    );
  }

  void _startWebTimer() {
    _webTimer?.cancel();
    _webTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _onWebTimerTick();
    });
  }

  void Function()? onWebSyncRequested;

  void _onWebTimerTick() {
    onWebSyncRequested?.call();
  }

  void dispose() {
    _webTimer?.cancel();
    _webTimer = null;

    if (!kIsWeb && Platform.isAndroid) {
      Workmanager().cancelByUniqueName(backgroundSyncTaskName);
    }

    _initialized = false;
  }
}
