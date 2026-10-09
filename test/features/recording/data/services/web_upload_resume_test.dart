import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/core/platform/web_file_store.dart';
import 'package:oral_collector/core/util/crc32c.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/direct_recording_uploader.dart';
import 'package:oral_collector/features/recording/data/services/web_audio_sweeper.dart';
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';

/// A browser upload over 5 MB goes the resumable way, which writes a shadow row
/// before the first byte leaves. When that upload is cut short the row survives
/// the reload, and it is the only thing left that could lead back to the audio
/// — the bytes themselves sit in browser storage under the key capture chose
/// (ENG-427).
///
/// These tests work from the outside: they run a real upload against a fake
/// network, then ask the database what survived and try to reach the bytes
/// through it. Nothing here asserts how the path is built or how the sweep
/// decides. The storage is `idb_shim`'s in-memory factory — the same complete
/// implementation of the IndexedDB API the browser exposes, running on the
/// plain Dart VM — so what these tests keep or lose is what a browser would.
class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Cuts the upload off after the shadow row is written, the way a closed lid or
/// a dropped connection does.
class _InterruptedUpload extends Fake implements ResumableUploadService {
  @override
  Future<ResumableUploadResult> uploadFromSource({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async => const ResumableUploadResult(success: false, error: 'offline');
}

class _CompletedUpload extends Fake implements ResumableUploadService {
  @override
  Future<ResumableUploadResult> uploadFromSource({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async =>
      const ResumableUploadResult(success: true, clientCrc32c: 'AAAAAA==');
}

void main() {
  late WebFileStore browserStorage;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late AuthenticatedClient auth;

  setUp(() {
    browserStorage = WebFileStore(newIdbFactoryMemory());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    repo = LocalRecordingRepository(db);

    final storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    var nextServerId = 0;
    final network = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/oc/recordings') {
        return http.Response(jsonEncode({'id': 'srv-${nextServerId++}'}), 201);
      }
      if (request.method == 'POST' && path.endsWith('/confirm-upload')) {
        return http.Response('{}', 200);
      }
      return http.Response('unexpected', 500);
    });
    auth = AuthenticatedClient(client: network, storage: storage);
  });

  DirectRecordingUploader uploaderThat(ResumableUploadService resumable) =>
      DirectRecordingUploader(
        client: auth,
        resumableUploadService: resumable,
        recordingRepo: repo,
      );

  int millisAgo(Duration age) =>
      DateTime.now().subtract(age).millisecondsSinceEpoch;

  String recordingKey(Duration age) => 'web_record_${millisAgo(age)}.webm';

  /// Over the uploader's 5 MB threshold, so the upload takes the resumable
  /// path, and not a uniform block, so a digest can tell it from other audio.
  Uint8List recordedBytes(int seed) {
    final bytes = Uint8List(5 * 1024 * 1024 + 1);
    for (var i = 0; i < bytes.length; i += 997) {
      bytes[i] = (i + seed) % 251;
    }
    return bytes;
  }

  String digestOf(Uint8List bytes) => (Crc32c()..add(bytes)).base64BigEndian;

  /// What `_saveWebDirect` hands the uploader on web: the bytes it just read
  /// back, and the storage key it read them from.
  FileSource capturedAudio(Uint8List bytes, String key) => FileSource.fromBytes(
    bytes,
    name: key,
    storageKey: key,
    mimeType: 'audio/webm',
  );

  DirectUploadMetadata metaFor(Uint8List bytes) => DirectUploadMetadata(
    projectId: 'proj-1',
    genreId: 'unclassified',
    subcategoryId: 'unclassified',
    storytellerId: 'st-1',
    userId: 'user-1',
    title: 'Uma gravação longa',
    durationSeconds: 900,
    fileSizeBytes: bytes.length,
    format: 'webm',
    recordedAt: DateTime.utc(2026, 8, 19, 10),
  );

  Future<void> sweep({DateTime? now}) => sweepOrphanWebAudio(
    listKeys: browserStorage.listKeys,
    deleteKey: browserStorage.delete,
    keysInUse: repo.getPendingWebUploadKeys,
    now: now,
  );

  test('the row an interrupted upload leaves behind finds the audio', () async {
    final key = recordingKey(const Duration(minutes: 3));
    final bytes = recordedBytes(1);
    await browserStorage.write(key, bytes);

    await expectLater(
      uploaderThat(
        _InterruptedUpload(),
      ).upload(source: capturedAudio(bytes, key), meta: metaFor(bytes)),
      throwsA(isA<Exception>()),
    );

    final pending = await repo.getPendingWebUploads();
    expect(pending, hasLength(1));

    final recovered = await browserStorage.read(pending.single.localFilePath);
    expect(recovered, hasLength(bytes.length));
    expect(digestOf(recovered), digestOf(bytes));
  });

  test('the sweep spares what a pending resume still needs', () async {
    final key = recordingKey(const Duration(hours: 48));
    final bytes = recordedBytes(2);
    await browserStorage.write(key, bytes);

    await expectLater(
      uploaderThat(
        _InterruptedUpload(),
      ).upload(source: capturedAudio(bytes, key), meta: metaFor(bytes)),
      throwsA(isA<Exception>()),
    );

    await sweep();

    expect(await browserStorage.exists(key), isTrue);
    expect(digestOf(await browserStorage.read(key)), digestOf(bytes));
  });

  test('the sweep still collects what really was abandoned', () async {
    // Left on the confirmation form two days ago and never uploaded: nothing
    // points at these bytes and nothing ever will (ENG-426).
    final abandoned = recordingKey(const Duration(hours: 48));
    await browserStorage.write(abandoned, recordedBytes(3));

    // Meanwhile a different recording does have an upload waiting to resume.
    // The sparing has to be per key: one that reads "some resume is pending"
    // as "collect nothing" turns the sweep off and would pass this test by
    // accident.
    final resuming = recordingKey(const Duration(hours: 50));
    final resumingBytes = recordedBytes(4);
    await browserStorage.write(resuming, resumingBytes);
    await expectLater(
      uploaderThat(_InterruptedUpload()).upload(
        source: capturedAudio(resumingBytes, resuming),
        meta: metaFor(resumingBytes),
      ),
      throwsA(isA<Exception>()),
    );

    await sweep();

    expect(await browserStorage.exists(abandoned), isFalse);
  });

  test('an upload that goes through leaves nothing behind', () async {
    final key = recordingKey(const Duration(minutes: 3));
    final bytes = recordedBytes(5);
    await browserStorage.write(key, bytes);

    await uploaderThat(
      _CompletedUpload(),
    ).upload(source: capturedAudio(bytes, key), meta: metaFor(bytes));

    expect(await repo.getPendingWebUploads(), isEmpty);

    // Nothing is holding the bytes, so tomorrow's sweep is free to take them.
    await sweep(now: DateTime.now().add(const Duration(hours: 25)));

    expect(await browserStorage.exists(key), isFalse);
  });
}
