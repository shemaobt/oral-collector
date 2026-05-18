import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recording/presentation/notifiers/recording_session_notifier.dart';
import '../../../recording/presentation/notifiers/recording_session_state.dart';
import '../../presentation/notifiers/sync_notifier.dart';
import 'upload_downloader.dart';

/// Glue between recording state and the background-upload pipeline:
///
/// * When recording starts (§1): cancel every in-flight upload task so the
///   `paused_by_recording` short-circuit fires inside `ResumableUploadService`
///   without waiting for the current chunk to finish.
/// * When recording ends: re-trigger `SyncNotifier.processQueue()` so any
///   uploads that were paused while recording resume from the persisted
///   offset (§3).
typedef ResumeTrigger = Future<void> Function();

class BackgroundUploadCoordinator {
  BackgroundUploadCoordinator({
    required UploadDownloader downloader,
    required ResumeTrigger onResume,
  }) : _downloader = downloader,
       _onResume = onResume;

  final UploadDownloader _downloader;
  final ResumeTrigger _onResume;

  bool _wasRecording = false;

  Future<void> onRecordingStateChanged(RecordingState state) async {
    final isRecordingNow = state.isRecording;
    if (isRecordingNow == _wasRecording) return;
    _wasRecording = isRecordingNow;

    if (isRecordingNow) {
      await _suspendForRecording();
    } else {
      await _resumeAfterRecording();
    }
  }

  Future<void> _suspendForRecording() async {
    try {
      await _downloader.cancelAll();
    } on Object catch (e) {
      debugPrint('BackgroundUploadCoordinator: cancelAll failed: $e');
    }
  }

  Future<void> _resumeAfterRecording() async {
    try {
      await _onResume();
    } on Object catch (e) {
      debugPrint('BackgroundUploadCoordinator: resume failed: $e');
    }
  }
}

final backgroundUploadCoordinatorProvider =
    Provider<BackgroundUploadCoordinator>((ref) {
      return BackgroundUploadCoordinator(
        downloader: const BackgroundDownloaderUploader(),
        onResume: () => ref.read(syncNotifierProvider.notifier).processQueue(),
      );
    });

/// Side-effect provider: subscribes to RecordingState transitions and forwards
/// them to the coordinator. Activate once at app startup by reading the
/// provider (e.g. `ref.read(recordingUploadListenerProvider)`).
final recordingUploadListenerProvider = Provider<void>((ref) {
  final coordinator = ref.read(backgroundUploadCoordinatorProvider);
  ref.listen<RecordingState>(recordingSessionNotifierProvider, (
    previous,
    next,
  ) {
    // Fire only when isRecording actually changes; the coordinator does its
    // own debouncing as a second line of defence.
    if (previous?.isRecording != next.isRecording) {
      unawaited(coordinator.onRecordingStateChanged(next));
    }
  }, fireImmediately: false);
});
