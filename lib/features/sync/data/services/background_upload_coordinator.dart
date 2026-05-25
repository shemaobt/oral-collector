import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recording/presentation/notifiers/recording_session_notifier.dart';
import '../../../recording/presentation/notifiers/recording_session_state.dart';
import '../../presentation/notifiers/sync_notifier.dart';
import '../providers.dart';
import 'upload_downloader.dart';
import 'upload_foreground_service.dart';

typedef ResumeTrigger = Future<void> Function();

class BackgroundUploadCoordinator {
  BackgroundUploadCoordinator({
    required UploadDownloader downloader,
    required UploadForegroundService uploadForegroundService,
    required ResumeTrigger onResume,
  }) : _downloader = downloader,
       _uploadForegroundService = uploadForegroundService,
       _onResume = onResume;

  final UploadDownloader _downloader;
  final UploadForegroundService _uploadForegroundService;
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
    // Owner-aware via ForegroundServiceArbiter; safe in any order with
    // recording taking over. No-op off Android / when idle.
    try {
      await _uploadForegroundService.stop();
    } on Object catch (e) {
      debugPrint('BackgroundUploadCoordinator: stop upload FGS failed: $e');
    }
  }

  Future<void> _resumeAfterRecording() async {
    try {
      await _downloader.resumeAfterCancel();
    } on Object catch (e) {
      debugPrint('BackgroundUploadCoordinator: resumeAfterCancel failed: $e');
    }
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
        downloader: ref.watch(uploadDownloaderProvider),
        uploadForegroundService: ref.watch(uploadForegroundServiceProvider),
        onResume: () => ref.read(syncNotifierProvider.notifier).processQueue(),
      );
    });

final recordingUploadListenerProvider = Provider<void>((ref) {
  final coordinator = ref.read(backgroundUploadCoordinatorProvider);
  ref.listen<RecordingState>(recordingSessionNotifierProvider, (
    previous,
    next,
  ) {
    if (previous?.isRecording != next.isRecording) {
      unawaited(coordinator.onRecordingStateChanged(next));
    }
  }, fireImmediately: false);
});
