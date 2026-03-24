import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

LocalRecording makeRecording({
  String id = 'rec-1',
  String uploadStatus = 'local',
  int fileSizeBytes = 1024,
  String? title = 'Test',
  int retryCount = 0,
}) => LocalRecording(
  id: id,
  projectId: 'proj-1',
  genreId: 'genre-1',
  subcategoryId: null,
  title: title,
  durationSeconds: 60.0,
  fileSizeBytes: fileSizeBytes,
  format: 'm4a',
  localFilePath: '/tmp/test.m4a',
  uploadStatus: uploadStatus,
  serverId: null,
  gcsUrl: null,
  registerId: null,
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: retryCount,
  lastRetryAt: null,
  resumableSessionUri: null,
  uploadedBytes: 0,
  md5Hash: null,
);

void main() {
  late ProviderContainer container;
  late MockConnectivity mockConnectivity;
  late MockSyncEngine mockSyncEngine;
  late MockRecordingRepo mockRecordingRepo;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockSyncEngine = MockSyncEngine();
    mockRecordingRepo = MockRecordingRepo();

    when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
    when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRecordingRepo.getPendingUploads(),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        connectivityServiceProvider.overrideWithValue(mockConnectivity),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        localRecordingRepositoryProvider.overrideWithValue(mockRecordingRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('initialization', () {
    test('default state has correct values', () {
      const state = SyncState();
      expect(state.isOnline, false);
      expect(state.pendingCount, 0);
      expect(state.uploadingId, isNull);
      expect(state.syncProgress, 0);
      expect(state.lastSyncAt, isNull);
      expect(state.autoUploadWifiOnly, true);
      expect(state.autoRemoveAfterUpload, true);
      expect(state.totalQueueSizeBytes, 0);
      expect(state.totalUploadedBytes, 0);
      expect(state.currentFileName, isNull);
      expect(state.uploadSpeedBps, 0);
      expect(state.estimatedTimeRemaining, isNull);
    });

    test('build checks connectivity and updates isOnline', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(syncNotifierProvider);
      expect(state.isOnline, true);
    });

    test('build sets isOnline to false when offline', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(syncNotifierProvider);
      expect(state.isOnline, false);
    });
  });

  group('connectivity handling', () {
    test('updates isOnline when connectivity changes', () async {
      final controller = StreamController<bool>();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(syncNotifierProvider).isOnline, true);

      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(syncNotifierProvider).isOnline, false);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(syncNotifierProvider).isOnline, true);

      await controller.close();
    });

    test(
      'triggers processQueue when transitioning from offline to online',
      () async {
        final controller = StreamController<bool>();
        when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        container.read(syncNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(syncNotifierProvider).isOnline, false);

        final pending = [makeRecording()];
        when(
          () => mockRecordingRepo.getPendingUploads(),
        ).thenAnswer((_) async => pending);
        when(
          () => mockSyncEngine.processQueue(
            deleteAfterUpload: any(named: 'deleteAfterUpload'),
            wifiOnly: any(named: 'wifiOnly'),
            maxConcurrency: any(named: 'maxConcurrency'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async {});

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockSyncEngine.processQueue(
            deleteAfterUpload: any(named: 'deleteAfterUpload'),
            wifiOnly: any(named: 'wifiOnly'),
            maxConcurrency: any(named: 'maxConcurrency'),
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);

        await controller.close();
      },
    );

    test('does NOT trigger processQueue when already online', () async {
      final controller = StreamController<bool>();
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      );

      await controller.close();
    });
  });

  group('syncOne', () {
    test('sets uploadingId and progress to 0', () async {
      final recording = makeRecording(id: 'rec-42', fileSizeBytes: 5000);
      when(
        () => mockRecordingRepo.getRecordingById('rec-42'),
      ).thenAnswer((_) async => recording);
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncOne('rec-42');

      verify(
        () => mockSyncEngine.uploadSingle(
          'rec-42',
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('calls uploadSingle, NOT processQueue', () async {
      final recording = makeRecording(id: 'rec-1');
      when(
        () => mockRecordingRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => recording);
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncOne('rec-1');

      verify(
        () => mockSyncEngine.uploadSingle(
          'rec-1',
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      verifyNever(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('clears uploadingId and sets progress to 100 on completion', () async {
      final recording = makeRecording(id: 'rec-1');
      when(
        () => mockRecordingRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => recording);
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncOne('rec-1');

      final state = container.read(syncNotifierProvider);
      expect(state.uploadingId, isNull);
      expect(state.syncProgress, 100);
      expect(state.lastSyncAt, isNotNull);
      expect(state.currentFileName, isNull);
    });

    test('handles exception gracefully', () async {
      final recording = makeRecording(id: 'rec-1');
      when(
        () => mockRecordingRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => recording);
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(Exception('upload failed'));

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncOne('rec-1');

      final state = container.read(syncNotifierProvider);
      expect(state.uploadingId, isNull);
      expect(state.syncProgress, 0);
      expect(state.currentFileName, isNull);
    });

    test('returns early when recording not found', () async {
      when(
        () => mockRecordingRepo.getRecordingById('missing'),
      ).thenAnswer((_) async => null);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncOne('missing');

      verifyNever(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test(
      'sets currentFileName and totalQueueSizeBytes from recording',
      () async {
        final recording = makeRecording(
          id: 'rec-1',
          title: 'My Song',
          fileSizeBytes: 9999,
        );
        when(
          () => mockRecordingRepo.getRecordingById('rec-1'),
        ).thenAnswer((_) async => recording);

        late SyncState capturedState;
        when(
          () => mockSyncEngine.uploadSingle(
            any(),
            deleteAfterUpload: any(named: 'deleteAfterUpload'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async {
          capturedState = container.read(syncNotifierProvider);
        });

        container.read(syncNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        await container.read(syncNotifierProvider.notifier).syncOne('rec-1');

        expect(capturedState.currentFileName, 'My Song');
        expect(capturedState.totalQueueSizeBytes, 9999);
        expect(capturedState.totalUploadedBytes, 0);
      },
    );
  });

  group('processQueue', () {
    test('returns early when offline', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      verifyNever(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('returns early when no pending recordings', () async {
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => []);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      verifyNever(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('sets initial state from pending recordings', () async {
      final recordings = [
        makeRecording(id: 'rec-1', fileSizeBytes: 1000, title: 'First'),
        makeRecording(id: 'rec-2', fileSizeBytes: 2000, title: 'Second'),
      ];

      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => recordings);

      late SyncState capturedState;
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {
        capturedState = container.read(syncNotifierProvider);
      });

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      expect(capturedState.uploadingId, 'rec-1');
      expect(capturedState.currentFileName, 'First');
      expect(capturedState.syncProgress, 0);
      expect(capturedState.totalQueueSizeBytes, 3000);
      expect(capturedState.totalUploadedBytes, 0);
      expect(capturedState.uploadSpeedBps, 0);
    });

    test('uses concurrency 3 on WiFi', () async {
      final recordings = [makeRecording()];
      int callCount = 0;
      when(() => mockRecordingRepo.getPendingUploads()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 2) return recordings;
        return [];
      });
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => true);
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      verify(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: 3,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('uses concurrency 1 when not on WiFi', () async {
      final recordings = [makeRecording()];
      int callCount = 0;
      when(() => mockRecordingRepo.getPendingUploads()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 2) return recordings;
        return [];
      });
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => false);
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      verify(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: 1,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('passes settings to processQueue', () async {
      final recordings = [makeRecording()];
      int callCount = 0;
      when(() => mockRecordingRepo.getPendingUploads()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 2) return recordings;
        return [];
      });
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: false,
              autoRemoveAfterUpload: false,
            ),
          );

      await container.read(syncNotifierProvider.notifier).processQueue();

      verify(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: false,
          wifiOnly: false,
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('sets lastSyncAt and progress 100 after completion', () async {
      final recordings = [makeRecording(fileSizeBytes: 500)];
      int callCount = 0;
      when(() => mockRecordingRepo.getPendingUploads()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 2) return recordings;
        return [];
      });
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      final state = container.read(syncNotifierProvider);
      expect(state.syncProgress, 100);
      expect(state.lastSyncAt, isNotNull);
      expect(state.uploadingId, isNull);
      expect(state.currentFileName, isNull);
      expect(state.uploadSpeedBps, 0);
    });
  });

  group('updateSettings', () {
    test('updates autoUploadWifiOnly', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: false,
              autoRemoveAfterUpload: true,
            ),
          );

      final state = container.read(syncNotifierProvider);
      expect(state.autoUploadWifiOnly, false);
      expect(state.autoRemoveAfterUpload, true);
    });

    test('updates autoRemoveAfterUpload', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: true,
              autoRemoveAfterUpload: false,
            ),
          );

      final state = container.read(syncNotifierProvider);
      expect(state.autoUploadWifiOnly, true);
      expect(state.autoRemoveAfterUpload, false);
    });

    test('updates both settings at once', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: false,
              autoRemoveAfterUpload: false,
            ),
          );

      final state = container.read(syncNotifierProvider);
      expect(state.autoUploadWifiOnly, false);
      expect(state.autoRemoveAfterUpload, false);
    });
  });

  group('resetAndRetry', () {
    test('calls resetRetryCount then syncOne', () async {
      when(
        () => mockRecordingRepo.resetRetryCount('rec-1'),
      ).thenAnswer((_) async => true);
      when(
        () => mockRecordingRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => makeRecording(id: 'rec-1'));
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(syncNotifierProvider.notifier)
          .resetAndRetry('rec-1');

      verify(() => mockRecordingRepo.resetRetryCount('rec-1')).called(1);
      verify(
        () => mockSyncEngine.uploadSingle(
          'rec-1',
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('refreshes pending count before syncing', () async {
      final recording = makeRecording(id: 'rec-5', retryCount: 3);
      when(
        () => mockRecordingRepo.resetRetryCount('rec-5'),
      ).thenAnswer((_) async => true);
      when(
        () => mockRecordingRepo.getRecordingById('rec-5'),
      ).thenAnswer((_) async => recording);
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [recording]);
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(syncNotifierProvider.notifier)
          .resetAndRetry('rec-5');

      verify(() => mockRecordingRepo.resetRetryCount('rec-5')).called(1);
      verify(
        () => mockRecordingRepo.getPendingUploads(),
      ).called(greaterThan(1));
    });
  });

  group('estimatedTimeRemaining', () {
    test('returns null when uploadSpeedBps is 0', () {
      const state = SyncState(
        totalQueueSizeBytes: 1000,
        totalUploadedBytes: 0,
        uploadSpeedBps: 0,
      );
      expect(state.estimatedTimeRemaining, isNull);
    });

    test('returns null when all bytes uploaded', () {
      const state = SyncState(
        totalQueueSizeBytes: 1000,
        totalUploadedBytes: 1000,
        uploadSpeedBps: 500,
      );
      expect(state.estimatedTimeRemaining, isNull);
    });

    test('calculates correct duration', () {
      const state = SyncState(
        totalQueueSizeBytes: 10000,
        totalUploadedBytes: 5000,
        uploadSpeedBps: 1000,
      );
      expect(state.estimatedTimeRemaining, const Duration(seconds: 5));
    });
  });
}
