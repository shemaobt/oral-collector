import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/url_scheme_data.dart';

import '../../../../core/config/recording_config.dart';

const recordingLiveActivityUrlScheme = RecordingConfig.liveActivityUrlScheme;

class RecordingLiveActivity {
  RecordingLiveActivity._();
  static final RecordingLiveActivity instance = RecordingLiveActivity._();

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;
  String? _activityId;

  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return false;
    try {
      await _ensureInitialized();
      final supported = await _plugin.areActivitiesSupported();
      if (!supported) return false;
      return await _plugin.areActivitiesEnabled();
    } on Exception catch (e) {
      debugPrint('RecordingLiveActivity: support check failed: $e');
      return false;
    }
  }

  Stream<UrlSchemeData> get urlSchemeStream => _plugin.urlSchemeStream();

  Future<bool> start({
    required String activityId,
    required String genre,
    required String subcategory,
  }) async {
    if (!await isSupported()) return false;
    try {
      final id = await _plugin.createActivity(activityId, {
        'genre': genre,
        'subcategory': subcategory,
        'elapsedLabel': '00:00',
        'startedAtEpoch': DateTime.now().millisecondsSinceEpoch.toString(),
        'isPaused': 'false',
      }, removeWhenAppIsKilled: true);
      if (id == null) return false;
      _activityId = id;
      return true;
    } on Exception catch (e) {
      debugPrint('RecordingLiveActivity: createActivity failed: $e');
      return false;
    }
  }

  Future<void> update({
    required String elapsedLabel,
    required bool isPaused,
  }) async {
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.updateActivity(id, {
        'elapsedLabel': elapsedLabel,
        'isPaused': isPaused ? 'true' : 'false',
      });
    } on Exception catch (e) {
      debugPrint('RecordingLiveActivity: updateActivity failed: $e');
    }
  }

  Future<void> stop() async {
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.endActivity(id);
    } on Exception catch (e) {
      debugPrint('RecordingLiveActivity: endActivity failed: $e');
    }
    _activityId = null;
  }

  Future<void> endAll() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _ensureInitialized();
      await _plugin.endAllActivities();
    } on Exception catch (e) {
      debugPrint('RecordingLiveActivity: endAllActivities failed: $e');
    }
    _activityId = null;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.init(
      appGroupId: RecordingConfig.appGroupId,
      urlScheme: RecordingConfig.liveActivityUrlScheme,
      requestAndroidNotificationPermission: false,
    );
    _initialized = true;
  }
}
