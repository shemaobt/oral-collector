import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/recording_config.dart';
import '../../../../core/platform/foreground_service_arbiter.dart';
import 'upload_foreground_task.dart';

/// Keeps the Android process alive while the upload queue runs, so uploads
/// continue while the app is minimized. Android-only (no-op on iOS/web).
class UploadForegroundService {
  UploadForegroundService();

  static final _log = Logger('UploadForegroundService');

  bool get isRunning =>
      ForegroundServiceArbiter.isOwner(ForegroundServiceOwner.upload);

  Future<void> start({
    required Future<String> Function() titleResolver,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (ForegroundServiceArbiter.isOwner(ForegroundServiceOwner.upload) &&
        await FlutterForegroundTask.isRunningService) {
      return;
    }

    // Resolve the title after the guards so l10n never runs off Android.
    String title;
    try {
      title = await titleResolver();
    } on Object catch (e) {
      _log.warning('title resolve failed', e);
      title = body;
    }

    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'upload_foreground',
          channelName: title,
          channelDescription: title,
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
          allowWifiLock: true,
        ),
      );
    } on Exception catch (e) {
      _log.warning('init failed', e);
      return;
    }

    try {
      await ForegroundServiceArbiter.takeOver(
        owner: ForegroundServiceOwner.upload,
        isRunning: () => FlutterForegroundTask.isRunningService,
        stop: () async {
          await FlutterForegroundTask.stopService();
        },
        start: () async {
          await FlutterForegroundTask.startService(
            serviceId: uploadServiceId,
            serviceTypes: const [ForegroundServiceTypes.dataSync],
            notificationTitle: title,
            notificationText: body,
            notificationIcon: const NotificationIcon(
              metaDataName: RecordingConfig.notificationIconMetadata,
            ),
            callback: startUploadTaskCallback,
          );
        },
      );
    } on Exception catch (e) {
      _log.warning('startService failed', e);
    }
  }

  Future<void> updateProgress({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!ForegroundServiceArbiter.isOwner(ForegroundServiceOwner.upload)) {
      return;
    }
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } on Exception catch (e) {
      _log.warning('updateService failed', e);
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await ForegroundServiceArbiter.release(
        owner: ForegroundServiceOwner.upload,
        isRunning: () => FlutterForegroundTask.isRunningService,
        stop: () async {
          await FlutterForegroundTask.stopService();
        },
      );
    } on Exception catch (e) {
      _log.warning('stopService failed', e);
    }
  }
}
