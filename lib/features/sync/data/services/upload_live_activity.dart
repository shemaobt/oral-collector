import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:live_activities/live_activities.dart';

import '../../../../core/config/recording_config.dart';

class UploadLiveActivity {
  UploadLiveActivity._();
  static final UploadLiveActivity instance = UploadLiveActivity._();

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;
  String? _activityId;

  bool _isAppForeground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

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
    if (!_isAppForeground()) {
      // iOS rejects createActivity when the host app is not foreground
      // ("Target is not foreground"). Skip silently; the caller can retry
      // when the app comes back to the foreground.
      return false;
    }
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

  bool get hasActivity => _activityId != null;

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
