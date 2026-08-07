/// "Clear local cache" must never destroy the only copy of a recording.
///
/// Reported from the field: an hour-long recording sat waiting to upload for
/// days, the user cleared the local cache, and the audio was gone. It had never
/// reached the server, so nothing else held it. The dialog said "uploaded
/// recordings on the server will not be affected", which is true and is exactly
/// what makes it dangerous — it answers for the recordings that are safe and
/// says nothing about the ones that are not.
///
/// The operation exists to free space by dropping copies the server already
/// has. Anything else is not cache.
library;

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

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// Records what was asked of it, so a test can assert on the rows that
/// survived rather than on the calls that were made.
class _FakeRepo implements LocalRecordingRepository {
  _FakeRepo(this._rows);

  List<LocalRecording> _rows;
  final deletedIds = <String>[];
  var deleteAllCalls = 0;

  @override
  Future<List<LocalRecording>> getAllLocalRecordings() async => _rows;

  @override
  Future<bool> deleteRecording(String id) async {
    deletedIds.add(id);
    final before = _rows.length;
    _rows = _rows.where((r) => r.id != id).toList();
    return _rows.length != before;
  }

  @override
  Future<int> deleteAllRecordings() async {
    deleteAllCalls++;
    final n = _rows.length;
    _rows = const [];
    return n;
  }

  @override
  Future<List<LocalRecording>> getPendingUploads() async =>
      _rows.where((r) => r.uploadStatus != 'uploaded').toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

LocalRecording _row({
  required String id,
  required String uploadStatus,
  String? serverId,
}) => LocalRecording(
  id: id,
  reviewFlagsJson: '[]',
  projectId: 'proj-1',
  genreId: 'genre-1',
  subcategoryId: null,
  title: id,
  durationSeconds: 3600,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/$id.m4a',
  uploadStatus: uploadStatus,
  serverId: serverId,
  gcsUrl: null,
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 8, 1),
  createdAt: DateTime(2026, 8, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

void main() {
  late _FakeRepo repo;

  ProviderContainer containerWith(List<LocalRecording> rows) {
    repo = _FakeRepo(rows);
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());

    final container = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        connectivityServiceProvider.overrideWithValue(connectivity),
        syncEngineProvider.overrideWithValue(_MockSyncEngine()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a recording waiting to upload survives the clear', () async {
    final container = containerWith([
      _row(id: 'pending', uploadStatus: 'local'),
      _row(id: 'sent', uploadStatus: 'uploaded', serverId: 'srv-1'),
    ]);

    await container.read(syncNotifierProvider.notifier).clearLocalCache();

    expect(repo.deletedIds, ['sent']);
    expect(await repo.getAllLocalRecordings(), [
      isA<LocalRecording>().having((r) => r.id, 'id', 'pending'),
    ]);
  });

  test('a failed upload is kept — a retry budget that ran out is not the '
      'server having the audio', () async {
    final container = containerWith([
      _row(id: 'failed', uploadStatus: 'failed'),
      _row(id: 'exhausted', uploadStatus: 'failed_exhausted'),
      _row(id: 'in-flight', uploadStatus: 'uploading'),
    ]);

    await container.read(syncNotifierProvider.notifier).clearLocalCache();

    expect(repo.deletedIds, isEmpty);
    expect((await repo.getAllLocalRecordings()).length, 3);
  });

  test('an "uploaded" row with no server id is kept, because the id is the '
      'evidence the server took it', () async {
    final container = containerWith([
      _row(id: 'no-server-id', uploadStatus: 'uploaded'),
      _row(id: 'verified', uploadStatus: 'verified', serverId: 'srv-2'),
    ]);

    await container.read(syncNotifierProvider.notifier).clearLocalCache();

    expect(repo.deletedIds, ['verified']);
  });

  test('the wipe-everything call is never used', () async {
    final container = containerWith([
      _row(id: 'pending', uploadStatus: 'local'),
      _row(id: 'sent', uploadStatus: 'uploaded', serverId: 'srv-1'),
    ]);

    await container.read(syncNotifierProvider.notifier).clearLocalCache();

    expect(repo.deleteAllCalls, 0);
  });

  test(
    'it reports how many it refused to delete, so the screen can say so',
    () async {
      final container = containerWith([
        _row(id: 'pending', uploadStatus: 'local'),
        _row(id: 'failed', uploadStatus: 'failed'),
        _row(id: 'sent', uploadStatus: 'uploaded', serverId: 'srv-1'),
      ]);

      final kept = await container
          .read(syncNotifierProvider.notifier)
          .clearLocalCache();

      expect(kept, 2);
    },
  );
}
