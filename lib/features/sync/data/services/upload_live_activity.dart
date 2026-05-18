import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

import '../../../../core/config/recording_config.dart';

/// Live Activity wrapper for the **upload** kind. Mirrors the structure of
/// [RecordingLiveActivity] but writes `kind: "upload"` into the App Group
/// UserDefaults so the SwiftUI widget can pick the upload layout instead of
/// the recording layout. Recording-LA and upload-LA never coexist (§1 mutex),
/// so it is safe to reuse the same widget extension target.
class UploadLiveActivity {
  UploadLiveActivity._();
  static final UploadLiveActivity instance = UploadLiveActivity._();

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
      debugPrint('UploadLiveActivity: support check failed: $e');
      return false;
    }
  }

  Future<bool> start({
    required String activityId,
    required String fileName,
    required int progressPercent,
  }) async {
    if (!await isSupported()) return false;
    try {
      final id = await _plugin.createActivity(activityId, {
        'kind': 'upload',
        'fileName': fileName,
        'progressPercent': progressPercent.toString(),
        'startedAtEpoch': DateTime.now().millisecondsSinceEpoch.toString(),
      }, removeWhenAppIsKilled: true);
      if (id == null) return false;
      _activityId = id;
      return true;
    } on Exception catch (e) {
      debugPrint('UploadLiveActivity: createActivity failed: $e');
      return false;
    }
  }

  Future<void> update({required int progressPercent}) async {
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.updateActivity(id, {
        'kind': 'upload',
        'progressPercent': progressPercent.toString(),
      });
    } on Exception catch (e) {
      debugPrint('UploadLiveActivity: updateActivity failed: $e');
    }
  }

  Future<void> stop() async {
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.endActivity(id);
    } on Exception catch (e) {
      debugPrint('UploadLiveActivity: endActivity failed: $e');
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
