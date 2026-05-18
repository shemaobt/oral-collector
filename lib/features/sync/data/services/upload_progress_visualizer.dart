import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/notifiers/sync_notifier.dart';
import '../../presentation/notifiers/sync_state.dart';
import 'upload_live_activity.dart';
import 'upload_notification.dart';

class UploadProgressVisualizer {
  UploadProgressVisualizer({
    UploadLiveActivity? liveActivity,
    UploadNotification? notification,
  }) : _liveActivity = liveActivity ?? UploadLiveActivity.instance,
       _notification = notification ?? UploadNotification.instance;

  final UploadLiveActivity _liveActivity;
  final UploadNotification _notification;
  String? _activeRecordingId;

  Future<void> onStateChanged(SyncState? previous, SyncState next) async {
    if (kIsWeb) return;

    final previousId = previous?.uploadingId;
    final nextId = next.uploadingId;
    final fileName = next.currentFileName ?? 'Recording';

    if (previousId == null && nextId != null) {
      _activeRecordingId = nextId;
      if (Platform.isIOS) {
        await _liveActivity.start(
          activityId: nextId,
          fileName: fileName,
          progressPercent: next.syncProgress,
        );
      } else if (Platform.isAndroid) {
        await _notification.showProgress(
          title: 'Uploading recording',
          body: fileName,
          progressPercent: next.syncProgress,
        );
      }
      return;
    }

    if (previousId != null && nextId == null) {
      _activeRecordingId = null;
      if (Platform.isIOS) {
        await _liveActivity.stop();
      } else if (Platform.isAndroid) {
        await _notification.clear();
      }
      return;
    }

    if (previousId != null && nextId != null && previousId != nextId) {
      _activeRecordingId = nextId;
      if (Platform.isIOS) {
        await _liveActivity.stop();
        await _liveActivity.start(
          activityId: nextId,
          fileName: fileName,
          progressPercent: next.syncProgress,
        );
      } else if (Platform.isAndroid) {
        await _notification.showProgress(
          title: 'Uploading recording',
          body: fileName,
          progressPercent: next.syncProgress,
        );
      }
      return;
    }

    if (nextId != null &&
        nextId == _activeRecordingId &&
        previous?.syncProgress != next.syncProgress) {
      if (Platform.isIOS) {
        await _liveActivity.update(progressPercent: next.syncProgress);
      } else if (Platform.isAndroid) {
        await _notification.showProgress(
          title: 'Uploading recording',
          body: fileName,
          progressPercent: next.syncProgress,
        );
      }
    }
  }
}

extension on UploadProgressVisualizer {
  Future<void> retryForegroundLiveActivity(SyncState current) async {
    if (kIsWeb || !Platform.isIOS) return;
    final id = current.uploadingId;
    if (id == null) return;
    if (_liveActivity.hasActivity) return;
    await _liveActivity.start(
      activityId: id,
      fileName: current.currentFileName ?? 'Recording',
      progressPercent: current.syncProgress,
    );
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

  final lifecycleListener = AppLifecycleListener(
    onResume: () {
      final current = ref.read(syncNotifierProvider);
      unawaited(visualizer.retryForegroundLiveActivity(current));
    },
  );
  ref.onDispose(lifecycleListener.dispose);
});
