import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/sync/data/services/background_upload_coordinator.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';

class _RecordingDownloader implements UploadDownloader {
  int cancelAllCount = 0;

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async => const UploadResult(statusCode: 200);

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }
}

void main() {
  group('BackgroundUploadCoordinator', () {
    test(
      'cancels in-flight tasks the first time recording transitions to true',
      () async {
        final downloader = _RecordingDownloader();
        var resumeCalls = 0;
        final coordinator = BackgroundUploadCoordinator(
          downloader: downloader,
          onResume: () async => resumeCalls++,
        );

        await coordinator.onRecordingStateChanged(
          const RecordingState(isRecording: true),
        );

        expect(downloader.cancelAllCount, 1);
        expect(resumeCalls, 0);
      },
    );

    test('does not cancel again if state remains recording', () async {
      final downloader = _RecordingDownloader();
      final coordinator = BackgroundUploadCoordinator(
        downloader: downloader,
        onResume: () async {},
      );

      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );
      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );

      expect(downloader.cancelAllCount, 1);
    });

    test('cancel only fires on transition false → true', () async {
      final downloader = _RecordingDownloader();
      final coordinator = BackgroundUploadCoordinator(
        downloader: downloader,
        onResume: () async {},
      );

      // Initial idle → idle should not cancel.
      await coordinator.onRecordingStateChanged(const RecordingState());
      expect(downloader.cancelAllCount, 0);

      // idle → recording: cancel once.
      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );
      expect(downloader.cancelAllCount, 1);
    });

    test('resume callback fires on transition recording → idle', () async {
      final downloader = _RecordingDownloader();
      var resumeCalls = 0;
      final coordinator = BackgroundUploadCoordinator(
        downloader: downloader,
        onResume: () async => resumeCalls++,
      );

      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );
      await coordinator.onRecordingStateChanged(const RecordingState());

      expect(resumeCalls, 1);
    });
  });
}
