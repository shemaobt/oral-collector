import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../../core/config/recording_config.dart';
import 'recording_foreground_task.dart';

class RecordingForegroundServiceContent {
  const RecordingForegroundServiceContent({
    required this.title,
    required this.body,
    required this.stopActionLabel,
  });

  final String title;
  final String body;
  final String stopActionLabel;
}

class RecordingForegroundService {
  RecordingForegroundService();

  bool _initialized = false;
  bool _running = false;
  void Function()? _onStopRequested;

  bool get isRunning => _running;

  Future<bool> start({
    required RecordingForegroundServiceContent content,
    required void Function() onStopRequested,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!_initialized) {
      try {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'recording_foreground',
            channelName: content.title,
            channelDescription: content.title,
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            onlyAlertOnce: true,
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.nothing(),
            autoRunOnBoot: false,
            autoRunOnMyPackageReplaced: false,
            allowWakeLock: true,
            allowWifiLock: false,
          ),
        );
        _initialized = true;
      } on Exception catch (e) {
        debugPrint('RecordingForegroundService: init failed: $e');
        return false;
      }
    }

    _onStopRequested = onStopRequested;
    FlutterForegroundTask.addTaskDataCallback(_onForegroundData);
    try {
      await FlutterForegroundTask.startService(
        serviceId: recordingServiceId,
        serviceTypes: const [ForegroundServiceTypes.microphone],
        notificationTitle: content.title,
        notificationText: content.body,
        notificationIcon: const NotificationIcon(
          metaDataName: RecordingConfig.notificationIconMetadata,
        ),
        notificationButtons: [
          NotificationButton(
            id: recordingStopButtonId,
            text: content.stopActionLabel,
          ),
        ],
        callback: startRecordingTaskCallback,
      );
      _running = true;
      return true;
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: startService failed: $e');
      return false;
    }
  }

  Future<void> update({required String title, required String body}) async {
    if (kIsWeb || !Platform.isAndroid || !_running) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: updateService failed: $e');
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    _onStopRequested = null;
    if (!_running) return;
    try {
      await FlutterForegroundTask.stopService();
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: stopService failed: $e');
    }
    _running = false;
  }

  void _onForegroundData(Object data) {
    if (data == recordingStopEventKey) {
      _onStopRequested?.call();
    }
  }
}
