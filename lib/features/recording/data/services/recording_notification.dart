import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RecordingNotification {
  RecordingNotification._();
  static final RecordingNotification instance = RecordingNotification._();

  static const _channelId = 'recording_active';
  static const _channelName = 'Recording';
  static const _channelDescription = 'Shown while a recording is in progress';
  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
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

  Future<void> showActive({required String title, required String body}) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    await _plugin.show(
      _notificationId,
      title,
      body,
      const NotificationDetails(
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
          category: AndroidNotificationCategory.service,
        ),
      ),
    );
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    if (!_initialized) return;
    await _plugin.cancel(_notificationId);
  }
}
