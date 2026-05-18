import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/notifiers/sync_notifier.dart';
import '../../presentation/notifiers/sync_state.dart';
import 'upload_live_activity.dart';

/// Mirrors SyncState (uploadingId, syncProgress, currentFileName) into the
/// iOS Upload Live Activity (§5). No-op on Android & web (Android relies on
/// `background_downloader`'s built-in progress notification configured at
/// startup).
class UploadProgressVisualizer {
  UploadProgressVisualizer({UploadLiveActivity? liveActivity})
    : _liveActivity = liveActivity ?? UploadLiveActivity.instance;

  final UploadLiveActivity _liveActivity;
  String? _activeRecordingId;

  Future<void> onStateChanged(SyncState? previous, SyncState next) async {
    if (kIsWeb) return;
    if (!Platform.isIOS) return;

    final previousId = previous?.uploadingId;
    final nextId = next.uploadingId;

    if (previousId == null && nextId != null) {
      _activeRecordingId = nextId;
      await _liveActivity.start(
        activityId: nextId,
        fileName: next.currentFileName ?? 'Recording',
        progressPercent: next.syncProgress,
      );
      return;
    }

    if (previousId != null && nextId == null) {
      _activeRecordingId = null;
      await _liveActivity.stop();
      return;
    }

    if (previousId != null && nextId != null && previousId != nextId) {
      // Different upload took over (rare). Restart LA.
      await _liveActivity.stop();
      _activeRecordingId = nextId;
      await _liveActivity.start(
        activityId: nextId,
        fileName: next.currentFileName ?? 'Recording',
        progressPercent: next.syncProgress,
      );
      return;
    }

    if (nextId != null &&
        nextId == _activeRecordingId &&
        previous?.syncProgress != next.syncProgress) {
      await _liveActivity.update(progressPercent: next.syncProgress);
    }
  }
}

final uploadProgressVisualizerProvider = Provider<UploadProgressVisualizer>(
  (_) => UploadProgressVisualizer(),
);

final uploadProgressVisualizerListenerProvider = Provider<void>((ref) {
  final visualizer = ref.read(uploadProgressVisualizerProvider);
  ref.listen<SyncState>(syncNotifierProvider, (previous, next) {
    unawaited(visualizer.onStateChanged(previous, next));
  });
});
