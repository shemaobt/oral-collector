import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/api_exception.dart';
import 'package:oral_collector/core/errors/app_exception.dart'
    show ConflictException;
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';
import 'package:oral_collector/features/recording/data/use_cases/save_recording_title.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';

class _MockApiRepo extends Mock implements RecordingApiRepository {}

class _MockLocalRepo extends Mock implements LocalRecordingRepository {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeCompanion extends Fake implements LocalRecordingsCompanion {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCompanion());
    registerFallbackValue(const UpdateRecordingRequest());
  });

  late _MockApiRepo apiRepo;
  late _MockLocalRepo localRepo;

  setUp(() {
    apiRepo = _MockApiRepo();
    localRepo = _MockLocalRepo();
    when(
      () => apiRepo.updateRecording(any(), any()),
    ).thenAnswer((_) async => (success: true, reviewFlags: null));

    when(
      () => localRepo.updateRecording(any(), any()),
    ).thenAnswer((_) async => true);
  });

  group('saveRecordingTitle', () {
    test('returns emptyRejected when title is empty', () async {
      final result = await saveRecordingTitle(
        recordingId: 'rec-1',
        currentTitle: 'Old',
        serverId: 'srv-1',
        newTitle: '',
        isWeb: false,
        isOnline: true,
        apiRepo: apiRepo,
        localRepo: localRepo,
      );

      expect(result, SaveTitleResult.emptyRejected);
      verifyNever(() => localRepo.updateRecording(any(), any()));
      verifyNever(() => apiRepo.updateRecording(any(), any()));
    });

    test('returns emptyRejected when title is only whitespace', () async {
      final result = await saveRecordingTitle(
        recordingId: 'rec-1',
        currentTitle: 'Old',
        serverId: 'srv-1',
        newTitle: '   ',
        isWeb: false,
        isOnline: true,
        apiRepo: apiRepo,
        localRepo: localRepo,
      );

      expect(result, SaveTitleResult.emptyRejected);
      verifyNever(() => localRepo.updateRecording(any(), any()));
      verifyNever(() => apiRepo.updateRecording(any(), any()));
    });

    test('returns noChange when trimmed title equals current', () async {
      final result = await saveRecordingTitle(
        recordingId: 'rec-1',
        currentTitle: 'Same',
        serverId: 'srv-1',
        newTitle: '  Same  ',
        isWeb: false,
        isOnline: true,
        apiRepo: apiRepo,
        localRepo: localRepo,
      );

      expect(result, SaveTitleResult.noChange);
      verifyNever(() => localRepo.updateRecording(any(), any()));
      verifyNever(() => apiRepo.updateRecording(any(), any()));
    });

    test(
      'on web, calls API with trimmed title and does NOT call local repo',
      () async {
        final result = await saveRecordingTitle(
          recordingId: 'rec-1',
          currentTitle: 'Old',
          serverId: 'srv-1',
          newTitle: '  New Title  ',
          isWeb: true,
          isOnline: true,
          apiRepo: apiRepo,
          localRepo: null,
        );

        expect(result, SaveTitleResult.saved);
        final request =
            verify(
                  () => apiRepo.updateRecording('srv-1', captureAny()),
                ).captured.single
                as UpdateRecordingRequest;
        expect(request.title, 'New Title');
      },
    );

    test('on web with null serverId, uses recordingId as the API id', () async {
      final result = await saveRecordingTitle(
        recordingId: 'rec-1',
        currentTitle: 'Old',
        serverId: null,
        newTitle: 'New',
        isWeb: true,
        isOnline: true,
        apiRepo: apiRepo,
        localRepo: null,
      );

      expect(result, SaveTitleResult.saved);
      final request =
          verify(
                () => apiRepo.updateRecording('rec-1', captureAny()),
              ).captured.single
              as UpdateRecordingRequest;
      expect(request.title, 'New');
    });

    test(
      'on mobile online with serverId: calls API BEFORE local repo',
      () async {
        final result = await saveRecordingTitle(
          recordingId: 'rec-1',
          currentTitle: 'Old',
          serverId: 'srv-1',
          newTitle: 'New',
          isWeb: false,
          isOnline: true,
          apiRepo: apiRepo,
          localRepo: localRepo,
        );

        expect(result, SaveTitleResult.saved);
        verifyInOrder([
          () => apiRepo.updateRecording('srv-1', any()),
          () => localRepo.updateRecording('rec-1', any()),
        ]);
      },
    );

    test('on mobile offline: calls local repo only, NOT API', () async {
      final result = await saveRecordingTitle(
        recordingId: 'rec-1',
        currentTitle: 'Old',
        serverId: 'srv-1',
        newTitle: 'New',
        isWeb: false,
        isOnline: false,
        apiRepo: apiRepo,
        localRepo: localRepo,
      );

      // The server already knows this recording and was not told, so this is a
      // local-only save — same answer saveRecordingDescription gives (ENG-399).
      expect(result, SaveTitleResult.savedLocallyOnly);
      verify(() => localRepo.updateRecording('rec-1', any())).called(1);
      verifyNever(() => apiRepo.updateRecording(any(), any()));
    });

    test(
      'on mobile with no serverId: calls local repo only, NOT API',
      () async {
        final result = await saveRecordingTitle(
          recordingId: 'rec-1',
          currentTitle: null,
          serverId: null,
          newTitle: 'New',
          isWeb: false,
          isOnline: true,
          apiRepo: apiRepo,
          localRepo: localRepo,
        );

        expect(result, SaveTitleResult.saved);
        verify(() => localRepo.updateRecording('rec-1', any())).called(1);
        verifyNever(() => apiRepo.updateRecording(any(), any()));
      },
    );

    test(
      'on mobile, when API throws, returns savedLocallyOnly (not failure)',
      () async {
        when(
          () => apiRepo.updateRecording(any(), any()),
        ).thenThrow(Exception('network down'));

        final result = await saveRecordingTitle(
          recordingId: 'rec-1',
          currentTitle: 'Old',
          serverId: 'srv-1',
          newTitle: 'New',
          isWeb: false,
          isOnline: true,
          apiRepo: apiRepo,
          localRepo: localRepo,
        );

        expect(result, SaveTitleResult.savedLocallyOnly);
        verify(() => localRepo.updateRecording('rec-1', any())).called(1);
      },
    );

    test(
      'on mobile, ForbiddenException from API is rethrown AND local DB is NOT written',
      () async {
        when(
          () => apiRepo.updateRecording(any(), any()),
        ).thenThrow(const ForbiddenException());

        await expectLater(
          saveRecordingTitle(
            recordingId: 'rec-1',
            currentTitle: 'Old',
            serverId: 'srv-1',
            newTitle: 'New',
            isWeb: false,
            isOnline: true,
            apiRepo: apiRepo,
            localRepo: localRepo,
          ),
          throwsA(isA<ForbiddenException>()),
        );

        verifyNever(() => localRepo.updateRecording(any(), any()));
      },
    );

    test(
      'on mobile, a 409 rename is rethrown AND the stored title is untouched',
      () async {
        // Driven through the real API repository over a 409 response and a real
        // Drift row: a stub that throws would pass even if the HTTP layer never
        // produced the conflict, which is exactly how this regressed once.
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final realLocalRepo = LocalRecordingRepository(db);
        await realLocalRepo.insertRecording(
          LocalRecordingsCompanion(
            id: const Value('rec-1'),
            projectId: const Value('proj-1'),
            genreId: const Value('genre-1'),
            title: const Value('Old'),
            localFilePath: const Value('/tmp/rec-1.m4a'),
            recordedAt: Value(DateTime.utc(2026, 1, 1)),
          ),
        );

        final storage = _MockSecureStorage();
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'test-token');
        final realApiRepo = RecordingApiRepositoryImpl(
          client: AuthenticatedClient(
            client: MockClient((_) async => http.Response('', 409)),
            storage: storage,
          ),
          reporter: const NoopErrorReporter(),
        );

        await expectLater(
          saveRecordingTitle(
            recordingId: 'rec-1',
            currentTitle: 'Old',
            serverId: 'srv-1',
            newTitle: 'Taken On The Server',
            isWeb: false,
            isOnline: true,
            apiRepo: realApiRepo,
            localRepo: realLocalRepo,
          ),
          throwsA(isA<ConflictException>()),
        );

        expect((await realLocalRepo.getRecordingById('rec-1'))!.title, 'Old');
      },
    );

    test(
      'on mobile, writes the trimmed title into the local DB companion',
      () async {
        await saveRecordingTitle(
          recordingId: 'rec-1',
          currentTitle: 'Old',
          serverId: null,
          newTitle: '   Trimmed Title   ',
          isWeb: false,
          isOnline: false,
          apiRepo: apiRepo,
          localRepo: localRepo,
        );

        final captured =
            verify(
                  () => localRepo.updateRecording('rec-1', captureAny()),
                ).captured.single
                as LocalRecordingsCompanion;

        expect(captured.title, const Value('Trimmed Title'));
      },
    );
  });
}
