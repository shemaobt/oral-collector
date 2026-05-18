import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UploadNotification {
  UploadNotification._();
  static final UploadNotification instance = UploadNotification._();

  static const _channelId = 'upload_active';
  static const _channelName = 'Upload';
  static const _channelDescription = 'Shown while a recording is uploading';
  static const _notificationId = 2001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.low,
            playSound: false,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showProgress({
    required String title,
    required String body,
    required int progressPercent,
  }) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    if (!_initialized) await init();

    await _plugin.show(
      _notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          ongoing: true,
          autoCancel: false,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showWhen: true,
          category: AndroidNotificationCategory.progress,
          showProgress: true,
          maxProgress: 100,
          progress: progressPercent.clamp(0, 100),
        ),
      ),
    );
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    if (!_initialized) return;
    await _plugin.cancel(_notificationId);
  }
}
