import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../../core/config/recording_config.dart';
import 'upload_foreground_task.dart';

/// Keeps the Android process alive while the upload queue runs, so uploads
/// continue while the app is minimized — mirroring how recording stays alive in
/// the background. The shared foreground service is declared with
/// `android:stopWithTask="true"` in the manifest, so swiping the app away kills
/// the process and stops the upload; it resumes from the saved GCS offset on the
/// next launch.
///
/// Android-only. On iOS/web this is a no-op: iOS uploads run via URLSession
/// background (background_downloader), which the OS keeps alive while minimized
/// and cancels on force-quit.
class UploadForegroundService {
  UploadForegroundService();

  bool _initialized = false;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start({
    required Future<String> Function() titleResolver,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isAndroid || _running) return;

    // Resolve the localized title only after the platform guard, so the
    // dependency on WidgetsBinding/locale never runs off Android (e.g. in unit
    // tests). Falls back to the body (file name) if resolution fails.
    String title;
    try {
      title = await titleResolver();
    } on Object catch (e) {
      debugPrint('UploadForegroundService: title resolve failed: $e');
      title = body;
    }

    if (!_initialized) {
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
        _initialized = true;
      } on Exception catch (e) {
        debugPrint('UploadForegroundService: init failed: $e');
        return;
      }
    }

    try {
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
      _running = true;
    } on Exception catch (e) {
      debugPrint('UploadForegroundService: startService failed: $e');
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid || !_running) return;
    try {
      await FlutterForegroundTask.stopService();
    } on Exception catch (e) {
      debugPrint('UploadForegroundService: stopService failed: $e');
    }
    _running = false;
  }
}
