import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

void main() {
  group('SyncState', () {
    test('default values', () {
      const state = SyncState();
      expect(state.isOnline, isFalse);
      expect(state.pendingCount, 0);
      expect(state.uploadingId, isNull);
      expect(state.syncProgress, 0);
      expect(state.lastSyncAt, isNull);
      expect(state.autoUploadWifiOnly, isTrue);
      expect(state.autoRemoveAfterUpload, isTrue);
      expect(state.totalQueueSizeBytes, 0);
      expect(state.totalUploadedBytes, 0);
      expect(state.currentFileName, isNull);
      expect(state.uploadSpeedBps, 0);
    });

    test('copyWith preserves values', () {
      const state = SyncState(isOnline: true, pendingCount: 5);
      final updated = state.copyWith(syncProgress: 50);

      expect(updated.isOnline, isTrue);
      expect(updated.pendingCount, 5);
      expect(updated.syncProgress, 50);
    });

    test('copyWith clearUploadingId', () {
      const state = SyncState(uploadingId: 'rec-1');
      final updated = state.copyWith(clearUploadingId: true);

      expect(updated.uploadingId, isNull);
    });

    test('copyWith clearCurrentFileName', () {
      const state = SyncState(currentFileName: 'test.m4a');
      final updated = state.copyWith(clearCurrentFileName: true);

      expect(updated.currentFileName, isNull);
    });

    test('estimatedTimeRemaining returns null when no speed', () {
      const state = SyncState(
        totalQueueSizeBytes: 1000,
        totalUploadedBytes: 500,
        uploadSpeedBps: 0,
      );
      expect(state.estimatedTimeRemaining, isNull);
    });

    test('estimatedTimeRemaining calculates correctly', () {
      const state = SyncState(
        totalQueueSizeBytes: 10000,
        totalUploadedBytes: 5000,
        uploadSpeedBps: 1000,
      );
      final eta = state.estimatedTimeRemaining!;
      expect(eta.inSeconds, 5);
    });

    test('estimatedTimeRemaining returns null when upload complete', () {
      const state = SyncState(
        totalQueueSizeBytes: 1000,
        totalUploadedBytes: 1000,
        uploadSpeedBps: 500,
      );
      expect(state.estimatedTimeRemaining, isNull);
    });

    test('copyWith queue tracking fields', () {
      const state = SyncState();
      final updated = state.copyWith(
        totalQueueSizeBytes: 50000,
        totalUploadedBytes: 10000,
        currentFileName: 'recording.m4a',
        uploadSpeedBps: 2048.5,
      );

      expect(updated.totalQueueSizeBytes, 50000);
      expect(updated.totalUploadedBytes, 10000);
      expect(updated.currentFileName, 'recording.m4a');
      expect(updated.uploadSpeedBps, 2048.5);
    });
  });

  group('SyncSettings', () {
    test('stores values', () {
      const settings = SyncSettings(
        autoUploadWifiOnly: false,
        autoRemoveAfterUpload: true,
      );
      expect(settings.autoUploadWifiOnly, isFalse);
      expect(settings.autoRemoveAfterUpload, isTrue);
    });
  });
}
