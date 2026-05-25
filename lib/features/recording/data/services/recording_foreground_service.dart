import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../../core/config/recording_config.dart';
import '../../../../core/platform/foreground_service_arbiter.dart';
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

  void Function()? _onStopRequested;

  bool get isRunning =>
      ForegroundServiceArbiter.isOwner(ForegroundServiceOwner.recording);

  Future<bool> start({
    required RecordingForegroundServiceContent content,
    required void Function() onStopRequested,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
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
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: init failed: $e');
      return false;
    }

    _onStopRequested = onStopRequested;
    FlutterForegroundTask.addTaskDataCallback(_onForegroundData);
    try {
      await ForegroundServiceArbiter.takeOver(
        owner: ForegroundServiceOwner.recording,
        isRunning: () => FlutterForegroundTask.isRunningService,
        stop: () async {
          await FlutterForegroundTask.stopService();
        },
        start: () async {
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
        },
      );
      return true;
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: startService failed: $e');
      return false;
    }
  }

  Future<void> update({required String title, required String body}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!ForegroundServiceArbiter.isOwner(ForegroundServiceOwner.recording)) {
      return;
    }
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
    try {
      await ForegroundServiceArbiter.release(
        owner: ForegroundServiceOwner.recording,
        isRunning: () => FlutterForegroundTask.isRunningService,
        stop: () async {
          await FlutterForegroundTask.stopService();
        },
      );
    } on Exception catch (e) {
      debugPrint('RecordingForegroundService: stopService failed: $e');
    }
  }

  void _onForegroundData(Object data) {
    if (data == recordingStopEventKey) {
      _onStopRequested?.call();
    }
  }
}
