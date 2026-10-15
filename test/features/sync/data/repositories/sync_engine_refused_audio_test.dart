library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/config/upload_retry_policy.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_upload_banners.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/providers.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:oral_collector/features/sync/data/services/upload_foreground_service.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/sync_engine_api.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _SilentForegroundService implements UploadForegroundService {
  @override
  bool get isRunning => false;

  @override
  Future<void> start({
    required Future<String> Function() titleResolver,
    required String body,
  }) async {}

  @override
  Future<void> updateProgress({
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> stop() async {}
}

class _RecordingDownloader implements UploadDownloader {
  final sentFiles = <String>[];

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async {
    sentFiles.add(filePath);
    return const UploadResult(statusCode: 200);
  }

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> resumeAfterCancel() async {}
}

const _refusedEditSentence =
    'O servidor recusou o áudio editado (%s). O áudio anterior continua publicado.';
const _refusedEditNoReason =
    'O servidor recusou o áudio editado. O áudio anterior continua publicado.';
const _refusedFirstUpload = 'O envio foi recusado. Você pode tentar de novo.';
const _exhausted =
    'O envio parou após várias tentativas. Você pode tentar de novo.';
const _retry = 'Tentar novamente';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late Directory tempDir;
  late _RecordingDownloader downloader;
  late File audio;
  late _MockConnectivity connectivity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    tempDir = Directory.systemTemp.createTempSync('sync_engine_refused');
    audio = File('${tempDir.path}/edited.m4a')..writeAsBytesSync([0, 1, 2]);
    downloader = _RecordingDownloader();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> insertRecording({
    String? gcsUrl,
    String uploadStatus = 'local',
    int retryCount = 0,
  }) async {
    await db
        .into(db.localRecordings)
        .insert(
          LocalRecordingsCompanion.insert(
            id: 'rec-1',
            projectId: 'proj-1',
            genreId: 'genre-1',
            localFilePath: audio.path,
            title: const Value('A recording'),
            description: const Value(
              'A description with enough substance to be accepted',
            ),
            serverId: const Value('srv-1'),
            gcsUrl: Value(gcsUrl),
            uploadStatus: Value(uploadStatus),
            retryCount: Value(retryCount),
            recordedAt: DateTime.utc(2026, 5, 1),
          ),
        );
  }

  SyncEngineImpl buildEngine(http.Response? Function() confirm) {
    final storage = _MockSecureStorage();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    final httpClient = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/oc/recordings/upload-url') {
        return http.Response(
          jsonEncode({
            'upload_url': 'https://storage.googleapis.com/test',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      }
      if (request.method == 'POST' && path.endsWith('/confirm-upload')) {
        final response = confirm();
        if (response == null) throw http.ClientException('connection reset');
        return response;
      }
      return http.Response('Not Found', 404);
    });
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: storage,
    );
    return SyncEngineImpl(
      recordingRepo: repo,
      storytellerRepo: LocalStorytellerRepository(db),
      connectivity: connectivity,
      client: authClient,
      recordingApi: apiRepoFor(authClient),
      uploadDownloader: downloader,
    );
  }

  http.Response refusal(String code) => http.Response(
    jsonEncode({'detail': 'refused', 'code': code}),
    400,
    headers: {'content-type': 'application/json'},
  );

  Future<void> showBanner(
    WidgetTester tester, {
    VoidCallback? onRetryUpload,
  }) async {
    final recording = (await repo.getRecordingEntityById('rec-1'))!;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecordingUploadBanners(
            recording: recording,
            canEdit: true,
            onEditDetails: () {},
            onRetryUpload: onRetryUpload ?? () {},
            onDelete: () {},
            onClearSecondary: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'a refused edit with a size mismatch says why and that the earlier audio is still published',
    (tester) async {
      await tester.runAsync(() async {
        await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');
        await buildEngine(() => refusal('UPLOAD_SIZE_MISMATCH')).processQueue();
        await showBanner(tester);
      });
      await tester.pump();

      expect(
        find.text(
          _refusedEditSentence.replaceFirst(
            '%s',
            'o tamanho do áudio não confere com o registrado',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(_retry), findsOneWidget);
    },
  );

  testWidgets(
    'a refused edit with a checksum mismatch says the content differs',
    (tester) async {
      await tester.runAsync(() async {
        await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');
        await buildEngine(
          () => refusal('UPLOAD_CHECKSUM_MISMATCH'),
        ).processQueue();
        await showBanner(tester);
      });
      await tester.pump();

      expect(
        find.text(
          _refusedEditSentence.replaceFirst(
            '%s',
            'o conteúdo do áudio chegou diferente do enviado',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  test('a refused edit keeps the edited file on the phone', () async {
    await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');

    await buildEngine(() => refusal('UPLOAD_SIZE_MISMATCH')).processQueue();

    expect(audio.existsSync(), isTrue);
    expect((await repo.getRecordingById('rec-1'))!.localFilePath, audio.path);
  });

  testWidgets(
    'a refused edit with an unknown code says it was refused without a reason',
    (tester) async {
      await tester.runAsync(() async {
        await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');
        await buildEngine(() => refusal('SOMETHING_NEW')).processQueue();
        await showBanner(tester);
      });
      await tester.pump();

      expect(find.text(_refusedEditNoReason), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
    },
  );

  testWidgets(
    'a refused edit with a non-JSON body says it was refused without a reason',
    (tester) async {
      await tester.runAsync(() async {
        await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');
        await buildEngine(
          () => http.Response('<html>bad gateway</html>', 400),
        ).processQueue();
        await showBanner(tester);
      });
      await tester.pump();

      expect(find.text(_refusedEditNoReason), findsOneWidget);
    },
  );

  testWidgets('a refused first upload says the sending was refused', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await insertRecording();
      await buildEngine(() => refusal('UPLOAD_OBJECT_MISSING')).processQueue();
      await showBanner(tester);
    });
    await tester.pump();

    expect(find.text(_refusedFirstUpload), findsOneWidget);
    expect(find.text(_retry), findsOneWidget);
  });

  testWidgets(
    'a retry budget spent on transport errors keeps today\'s sentence',
    (tester) async {
      await tester.runAsync(() async {
        await insertRecording(
          gcsUrl: 'https://storage.example/earlier.m4a',
          uploadStatus: 'failed',
          retryCount: kMaxUploadRetries - 1,
        );
        await buildEngine(() => null).processQueue();
        await showBanner(tester);
      });
      await tester.pump();

      expect(find.text(_exhausted), findsOneWidget);
    },
  );

  test(
    'pressing Tentar novamente on a refused edit puts the same local file back in the queue',
    () async {
      await insertRecording(gcsUrl: 'https://storage.example/earlier.m4a');
      var answers = 0;
      final engine = buildEngine(() {
        answers++;
        return answers == 1
            ? refusal('UPLOAD_SIZE_MISMATCH')
            : http.Response(jsonEncode({'gcs_url': 'gs://b/new.m4a'}), 200);
      });
      await engine.processQueue();
      expect(await repo.getPendingUploads(), isEmpty);

      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivity),
          syncEngineProvider.overrideWithValue(engine),
          localRecordingRepositoryProvider.overrideWithValue(repo),
          uploadForegroundServiceProvider.overrideWithValue(
            _SilentForegroundService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(syncNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(syncNotifierProvider.notifier)
          .resetAndRetry('rec-1');

      expect(downloader.sentFiles, [audio.path, audio.path]);
      final row = (await repo.getRecordingById('rec-1'))!;
      expect((row.uploadStatus, row.retryCount), ('uploaded', 0));
    },
  );
}
