import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/data/services/upload_foreground_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

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

LocalRecording makeRecording({
  String id = 'rec-1',
  String uploadStatus = 'local',
  int fileSizeBytes = 1024,
  String? title = 'Test',
  int retryCount = 0,
  String localFilePath = '/tmp/test.m4a',
}) => LocalRecording(
  id: id,
  reviewFlagsJson: '[]',
  projectId: 'proj-1',
  genreId: 'genre-1',
  subcategoryId: null,
  title: title,
  durationSeconds: 60.0,
  fileSizeBytes: fileSizeBytes,
  format: 'm4a',
  localFilePath: localFilePath,
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockConnectivity mockConnectivity;
  late MockSyncEngine mockSyncEngine;
  late MockRecordingRepo mockRecordingRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    when(
      () => mockSyncEngine.processQueue(
        deleteAfterUpload: any(named: 'deleteAfterUpload'),
        wifiOnly: any(named: 'wifiOnly'),
        maxConcurrency: any(named: 'maxConcurrency'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});

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

  group('connectivity init race', () {
    test(
      'a connectivity change during init is not lost (subscribe before await)',
      () async {
        // connectivity_plus exposes a broadcast stream: events emitted before a
        // listener attaches are dropped (no replay). If the notifier subscribes
        // only AFTER awaiting the initial isOnline snapshot, a flip during that
        // await window is missed.
        final isOnlineGate = Completer<bool>();
        final connChanges = StreamController<bool>.broadcast();
        addTearDown(connChanges.close);

        when(
          () => mockConnectivity.isOnline,
        ).thenAnswer((_) => isOnlineGate.future);
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => connChanges.stream);

        container.read(syncNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        // The device comes online WHILE the initial snapshot is still pending.
        connChanges.add(true);
        await Future<void>.delayed(Duration.zero);

        // The snapshot resolves stale (offline) only afterwards; it must not
        // clobber the fresher event the listener already observed.
        isOnlineGate.complete(false);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(syncNotifierProvider).isOnline, true);
      },
    );
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
    test('a concurrent call does not stop the foreground service while the '
        'first run is still uploading', () async {
      final fakeFgs = _FakeUploadForegroundService();
      final engineGate = Completer<void>();

      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [makeRecording()]);
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => engineGate.future);

      final c = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localRecordingRepositoryProvider.overrideWithValue(mockRecordingRepo),
          uploadForegroundServiceProvider.overrideWithValue(fakeFgs),
        ],
      );
      addTearDown(c.dispose);

      final notifier = c.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final first = notifier.processQueue();
      await Future<void>.delayed(Duration.zero);
      await notifier.processQueue();

      expect(fakeFgs.startCount, 1);
      expect(fakeFgs.stopCount, 0);

      engineGate.complete();
      await first;

      expect(fakeFgs.stopCount, 1);
    });

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

    test('delegates to engine even when no recordings are pending '
        '(storytellers may need sync)', () async {
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => []);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).processQueue();

      verify(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
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

      // Cellular uploads have to be allowed for the queue to run at all
      // (ENG-355); what is under test is that the network type still decides
      // the concurrency.
      await container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: false,
              autoRemoveAfterUpload: true,
            ),
          );

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

      await container
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

  group('upload guard', () {
    test('syncOne bails while processQueue is in flight', () async {
      final fakeFgs = _FakeUploadForegroundService();
      final engineGate = Completer<void>();

      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [makeRecording()]);
      when(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => engineGate.future);
      // syncOne's path is stubbed so RED fails on the verifyNever assertion
      // rather than on a missing stub.
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

      final c = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localRecordingRepositoryProvider.overrideWithValue(mockRecordingRepo),
          uploadForegroundServiceProvider.overrideWithValue(fakeFgs),
        ],
      );
      addTearDown(c.dispose);

      final notifier = c.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final first = notifier.processQueue();
      await notifier.syncOne('rec-1');

      verifyNever(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      );

      engineGate.complete();
      await first;
    });

    test('processQueue bails while syncOne is in flight', () async {
      final fakeFgs = _FakeUploadForegroundService();
      final uploadGate = Completer<void>();

      when(
        () => mockRecordingRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => makeRecording(id: 'rec-1'));
      when(
        () => mockSyncEngine.uploadSingle(
          any(),
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => uploadGate.future);
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [makeRecording()]);

      final c = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localRecordingRepositoryProvider.overrideWithValue(mockRecordingRepo),
          uploadForegroundServiceProvider.overrideWithValue(fakeFgs),
        ],
      );
      addTearDown(c.dispose);

      final notifier = c.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final first = notifier.syncOne('rec-1');
      await notifier.processQueue();

      verifyNever(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: any(named: 'wifiOnly'),
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      );
      expect(fakeFgs.startCount, 0);
      // syncOne genuinely holds the guard: it set uploadingId before its first
      // await, so processQueue bailed on a real in-flight upload (not offline).
      expect(c.read(syncNotifierProvider).uploadingId, 'rec-1');

      uploadGate.complete();
      await first;
    });
  });

  group('updateSettings', () {
    test('updates autoUploadWifiOnly', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
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

      await container
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

      await container
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
    // Also guards the upload-guard pitfall: resetAndRetry calls syncOne, so it
    // must NOT acquire the shared guard itself — otherwise the inner syncOne
    // would re-entrantly bail and silently skip the upload.
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

  group('getLocalStorageUsed', () {
    test('sums existing local file sizes and skips missing files', () async {
      final dir = Directory.systemTemp.createTempSync('sync_storage_used');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/a.m4a').writeAsBytesSync(List.filled(100, 0));
      File('${dir.path}/b.m4a').writeAsBytesSync(List.filled(250, 0));

      when(() => mockRecordingRepo.getAllLocalRecordings()).thenAnswer(
        (_) async => [
          makeRecording(id: 'a', localFilePath: '${dir.path}/a.m4a'),
          makeRecording(id: 'b', localFilePath: '${dir.path}/b.m4a'),
          makeRecording(id: 'c', localFilePath: '${dir.path}/missing.m4a'),
        ],
      );

      final notifier = container.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(await notifier.getLocalStorageUsed(), 350);
    });
  });

  group('clearLocalCache', () {
    test('deletes every local file and then clears the repository', () async {
      final dir = Directory.systemTemp.createTempSync('sync_storage_clear');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final a = File('${dir.path}/a.m4a')..writeAsBytesSync(List.filled(10, 0));
      final b = File('${dir.path}/b.m4a')..writeAsBytesSync(List.filled(10, 0));

      when(() => mockRecordingRepo.getAllLocalRecordings()).thenAnswer(
        (_) async => [
          makeRecording(id: 'a', localFilePath: a.path),
          makeRecording(id: 'b', localFilePath: b.path),
        ],
      );
      when(() => mockRecordingRepo.deleteAllRecordings()).thenAnswer((_) async {
        // Ordering contract: files are deleted before the repository is cleared.
        expect(a.existsSync(), isFalse);
        expect(b.existsSync(), isFalse);
        return 2;
      });

      final notifier = container.read(syncNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await notifier.clearLocalCache();

      expect(a.existsSync(), isFalse);
      expect(b.existsSync(), isFalse);
      verify(() => mockRecordingRepo.deleteAllRecordings()).called(1);
    });
  });

  // The Wi-Fi-only gate used to be a silent return inside the engine: the
  // notifier then wrote lastSyncAt and progress 100 for a queue that never ran,
  // and nothing told the user why the tap did nothing. See ENG-355.
  group('wifi-only gate', () {
    setUp(() {
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => false);
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [makeRecording()]);
    });

    test('does not report a sync that never ran', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncAll();

      final state = container.read(syncNotifierProvider);
      expect(state.lastSyncAt, isNull);
      expect(state.syncProgress, isNot(100));
      expect(state.pendingCount, 1);
    });

    test('exposes why the queue was held back', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncAll();

      expect(
        container.read(syncNotifierProvider).blockReason,
        SyncBlockReason.wifiOnly,
      );
    });

    test('does not keep blaming Wi-Fi once the device is offline', () async {
      final controller = StreamController<bool>();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);
      addTearDown(controller.close);

      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(syncNotifierProvider.notifier).syncAll();
      expect(
        container.read(syncNotifierProvider).blockReason,
        SyncBlockReason.wifiOnly,
      );

      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      await container.read(syncNotifierProvider.notifier).syncAll();

      expect(container.read(syncNotifierProvider).blockReason, isNull);
    });

    test('clears the block once the device is back on Wi-Fi', () async {
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container.read(syncNotifierProvider.notifier).syncAll();
      expect(
        container.read(syncNotifierProvider).blockReason,
        SyncBlockReason.wifiOnly,
      );

      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => true);
      await container.read(syncNotifierProvider.notifier).syncAll();

      final state = container.read(syncNotifierProvider);
      expect(state.blockReason, isNull);
      expect(state.lastSyncAt, isNotNull);
    });
  });

  // The Wi-Fi-only preference was state-only: turning it off lasted until the
  // app was closed, and a device living on cellular went back to a frozen queue
  // on every relaunch. See ENG-355.
  group('settings persistence', () {
    ProviderContainer relaunch() {
      final relaunched = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
          localRecordingRepositoryProvider.overrideWithValue(mockRecordingRepo),
        ],
      );
      addTearDown(relaunched.dispose);
      return relaunched;
    }

    test('wifi-only stays off after a relaunch', () async {
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => false);
      when(
        () => mockRecordingRepo.getPendingUploads(),
      ).thenAnswer((_) async => [makeRecording()]);

      await container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: false,
              autoRemoveAfterUpload: true,
            ),
          );
      container.dispose();

      // A fresh container is a fresh notifier: whatever it knows came from
      // storage. Asserted through the effective behaviour of the next sync,
      // not by reading the preference key back.
      final relaunched = relaunch();
      relaunched.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await relaunched.read(syncNotifierProvider.notifier).syncAll();

      expect(relaunched.read(syncNotifierProvider).blockReason, isNull);
      verify(
        () => mockSyncEngine.processQueue(
          deleteAfterUpload: any(named: 'deleteAfterUpload'),
          wifiOnly: false,
          maxConcurrency: any(named: 'maxConcurrency'),
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('auto-remove stays off after a relaunch', () async {
      await container
          .read(syncNotifierProvider.notifier)
          .updateSettings(
            const SyncSettings(
              autoUploadWifiOnly: true,
              autoRemoveAfterUpload: false,
            ),
          );
      container.dispose();

      final relaunched = relaunch();
      relaunched.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        relaunched.read(syncNotifierProvider).autoRemoveAfterUpload,
        isFalse,
      );
    });
  });
}
