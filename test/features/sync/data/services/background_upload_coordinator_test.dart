import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/sync/data/services/background_upload_coordinator.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:oral_collector/features/sync/data/services/upload_foreground_service.dart';

class _RecordingDownloader implements UploadDownloader {
  int cancelAllCount = 0;
  int resumeAfterCancelCount = 0;

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

  @override
  Future<void> resumeAfterCancel() async {
    resumeAfterCancelCount++;
  }
}

class _FakeUploadForegroundService implements UploadForegroundService {
  int startCount = 0;
  int stopCount = 0;

  @override
  bool get isRunning => false;

  @override
  Future<void> start({
    required Future<String> Function() titleResolver,
    required String body,
  }) async {
    startCount++;
  }

  @override
  Future<void> updateProgress({
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> stop() async {
    stopCount++;
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
          uploadForegroundService: _FakeUploadForegroundService(),
          onResume: () async => resumeCalls++,
        );

        await coordinator.onRecordingStateChanged(
          const RecordingState(isRecording: true),
        );

        expect(downloader.cancelAllCount, 1);
        expect(resumeCalls, 0);
      },
    );

    test('stops the upload foreground service when recording starts', () async {
      final downloader = _RecordingDownloader();
      final fgs = _FakeUploadForegroundService();
      final coordinator = BackgroundUploadCoordinator(
        downloader: downloader,
        uploadForegroundService: fgs,
        onResume: () async {},
      );

      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );

      expect(fgs.stopCount, 1);
      expect(downloader.cancelAllCount, 1);
    });

    test('does not cancel again if state remains recording', () async {
      final downloader = _RecordingDownloader();
      final coordinator = BackgroundUploadCoordinator(
        downloader: downloader,
        uploadForegroundService: _FakeUploadForegroundService(),
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
        uploadForegroundService: _FakeUploadForegroundService(),
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
        uploadForegroundService: _FakeUploadForegroundService(),
        onResume: () async => resumeCalls++,
      );

      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );
      await coordinator.onRecordingStateChanged(const RecordingState());

      expect(resumeCalls, 1);
    });

    test('resumeAfterCancel is invoked before onResume so cancel state clears '
        'before the next processQueue', () async {
      final downloader = _RecordingDownloader();
      final callOrder = <String>[];
      final coordinator = BackgroundUploadCoordinator(
        downloader: _OrderingDownloader(downloader, callOrder),
        uploadForegroundService: _FakeUploadForegroundService(),
        onResume: () async => callOrder.add('onResume'),
      );

      await coordinator.onRecordingStateChanged(
        const RecordingState(isRecording: true),
      );
      callOrder.clear();
      await coordinator.onRecordingStateChanged(const RecordingState());

      expect(callOrder, ['resumeAfterCancel', 'onResume']);
    });

    test(
      'rapid true→false→true toggles fire cancelAll twice but resume once',
      () async {
        // §1: each new recording transition must cancel any in-flight chunk.
        // Intermediate idle states fire onResume only if they actually
        // represent an idle period (edge-triggered). This guards against the
        // double-toggle race the reviewer flagged.
        final downloader = _RecordingDownloader();
        var resumeCalls = 0;
        final coordinator = BackgroundUploadCoordinator(
          downloader: downloader,
          uploadForegroundService: _FakeUploadForegroundService(),
          onResume: () async => resumeCalls++,
        );

        await coordinator.onRecordingStateChanged(
          const RecordingState(isRecording: true),
        );
        await coordinator.onRecordingStateChanged(const RecordingState());
        await coordinator.onRecordingStateChanged(
          const RecordingState(isRecording: true),
        );

        expect(downloader.cancelAllCount, 2);
        expect(resumeCalls, 1);
        expect(downloader.resumeAfterCancelCount, 1);
      },
    );
  });
}

class _OrderingDownloader implements UploadDownloader {
  _OrderingDownloader(this._inner, this._calls);

  final _RecordingDownloader _inner;
  final List<String> _calls;

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) => _inner.putChunk(
    taskId: taskId,
    url: url,
    filePath: filePath,
    offset: offset,
    end: end,
    headers: headers,
  );

  @override
  Future<void> cancel(String taskId) => _inner.cancel(taskId);

  @override
  Future<void> cancelAll() async {
    _calls.add('cancelAll');
    await _inner.cancelAll();
  }

  @override
  Future<void> resumeAfterCancel() async {
    _calls.add('resumeAfterCancel');
    await _inner.resumeAfterCancel();
  }
}
