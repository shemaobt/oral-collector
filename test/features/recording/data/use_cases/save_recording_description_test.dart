/// A description edited on a phone has to reach the server (ENG-380).
///
/// It did not: the write went straight to the local row, and an uploaded
/// recording never returns to the queue, so the correction stayed on that one
/// device — invisible to everyone else and lost on reinstall. It also kept the
/// server's `insufficient_description` flag open forever, which is what left
/// the guided flow's "Describe" step unable to close.
///
/// The title, ten lines above it in the same function, already did this
/// correctly. This mirrors it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/errors/api_exception.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/use_cases/save_recording_description.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';

class _MockApiRepo extends Mock implements RecordingApiRepository {}

class _MockLocalRepo extends Mock implements LocalRecordingRepository {}

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
      () => localRepo.updateDescription(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => localRepo.updateReviewFlags(any(), any()),
    ).thenAnswer((_) async => true);
  });

  Future<SaveDescriptionResult> save({
    String? serverId = 'srv-1',
    bool isWeb = false,
    bool isOnline = true,
    String description = 'Uma descrição longa o bastante para o piso da regra',
  }) => saveRecordingDescription(
    recordingId: 'rec-1',
    serverId: serverId,
    description: description,
    isWeb: isWeb,
    isOnline: isOnline,
    apiRepo: apiRepo,
    localRepo: localRepo,
  );

  test(
    'a recording the server knows about is corrected on the server',
    () async {
      final result = await save();

      verify(() => apiRepo.updateRecording('srv-1', any())).called(1);
      verify(() => localRepo.updateDescription('rec-1', any())).called(1);
      expect(result, SaveDescriptionResult.saved);
    },
  );

  test(
    'a recording that never left the device is written locally only',
    () async {
      // Nothing to correct on the server yet — the description rides along with
      // the upload.
      final result = await save(serverId: null);

      verifyNever(() => apiRepo.updateRecording(any(), any()));
      verify(() => localRepo.updateDescription('rec-1', any())).called(1);
      expect(result, SaveDescriptionResult.saved);
    },
  );

  test(
    'offline, the edit is kept and the caller is told it did not sync',
    () async {
      final result = await save(isOnline: false);

      verifyNever(() => apiRepo.updateRecording(any(), any()));
      verify(() => localRepo.updateDescription('rec-1', any())).called(1);
      // Not `saved`: the screen must not claim the correction reached the server.
      expect(result, SaveDescriptionResult.savedLocallyOnly);
    },
  );

  test(
    'a network failure keeps the edit rather than losing what was typed',
    () async {
      when(
        () => apiRepo.updateRecording(any(), any()),
      ).thenThrow(Exception('connection reset'));

      final result = await save();

      verify(() => localRepo.updateDescription('rec-1', any())).called(1);
      expect(result, SaveDescriptionResult.savedLocallyOnly);
    },
  );

  test('a refusal is reported, not papered over with a local write', () async {
    when(
      () => apiRepo.updateRecording(any(), any()),
    ).thenThrow(const ForbiddenException());

    await expectLater(save(), throwsA(isA<ForbiddenException>()));
    // Writing locally here would leave the row disagreeing with the server
    // about a change the server refused.
    verifyNever(() => localRepo.updateDescription(any(), any()));
  });

  test('what the server says the recording still owes is stored', () async {
    when(() => apiRepo.updateRecording(any(), any())).thenAnswer(
      (_) async => (
        success: true,
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
        ],
      ),
    );

    await save();

    // This is what closes the guided flow's Describe step: the server drops
    // insufficient_description on recompute, and the row has to learn that.
    final captured =
        verify(
              () => localRepo.updateReviewFlags('rec-1', captureAny()),
            ).captured.single
            as List<ReviewFlag>;
    expect(captured.map((f) => f.code), ['missing_storyteller']);
  });

  test(
    'a server that says nothing about flags leaves the stored ones',
    () async {
      await save();

      verifyNever(() => localRepo.updateReviewFlags(any(), any()));
    },
  );

  test('on web the server is the only writer', () async {
    final result = await save(isWeb: true);

    verify(() => apiRepo.updateRecording('srv-1', any())).called(1);
    verifyNever(() => localRepo.updateDescription(any(), any()));
    expect(result, SaveDescriptionResult.saved);
  });
}
