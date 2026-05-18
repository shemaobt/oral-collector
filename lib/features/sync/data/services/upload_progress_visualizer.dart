import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/recording_active_flag.dart';
import '../../presentation/notifiers/sync_notifier.dart';
import '../../presentation/notifiers/sync_state.dart';
import 'upload_live_activity.dart';
import 'upload_notification.dart';

class UploadProgressVisualizer {
  UploadProgressVisualizer({
    UploadLiveActivity? liveActivity,
    UploadNotification? notification,
    RecordingActiveFlag? recordingFlag,
  }) : _liveActivity = liveActivity ?? UploadLiveActivity.instance,
       _notification = notification ?? UploadNotification.instance,
       _recordingFlag = recordingFlag ?? const RecordingActiveFlag();

  final UploadLiveActivity _liveActivity;
  final UploadNotification _notification;
  final RecordingActiveFlag _recordingFlag;
  String? _activeRecordingId;
  // Track the last shown integer-percent so we don't rebuild the Android
  // notification view on every minor float update (the upload coordinator
  // can fire dozens of progress events per chunk).
  int _lastShownPercent = -1;

  Future<void> onStateChanged(SyncState? previous, SyncState next) async {
    if (kIsWeb) return;

    final previousId = previous?.uploadingId;
    final nextId = next.uploadingId;
    final fileName = next.currentFileName ?? 'Recording';

    if (previousId == null && nextId != null) {
      // §1 invariant: if a recording is active, don't surface upload UI at
      // all. The upload loop itself short-circuits on the same flag, but the
      // visualizer is wired independently — a stray sync state event during
      // the recording-start transition could otherwise pop a notification
      // on top of the recording one.
      if (await _recordingFlag.read()) return;

      _activeRecordingId = nextId;
      _lastShownPercent = (next.syncProgress * 100).round();
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
      _lastShownPercent = -1;
      if (Platform.isIOS) {
        await _liveActivity.stop();
      } else if (Platform.isAndroid) {
        await _notification.clear();
      }
      return;
    }

    if (previousId != null && nextId != null && previousId != nextId) {
      _activeRecordingId = nextId;
      _lastShownPercent = (next.syncProgress * 100).round();
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
      final nextPercent = (next.syncProgress * 100).round();
      if (Platform.isIOS) {
        // iOS Live Activity has its own per-update budget; let it through.
        await _liveActivity.update(progressPercent: next.syncProgress);
      } else if (Platform.isAndroid) {
        // Skip if the integer-percent hasn't moved — onlyAlertOnce already
        // suppresses sound but the notification view still rebuilds.
        if (nextPercent == _lastShownPercent) return;
        _lastShownPercent = nextPercent;
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
