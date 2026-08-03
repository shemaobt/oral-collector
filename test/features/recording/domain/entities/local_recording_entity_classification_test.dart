/// `isUnclassified` answers from the same place the guided flow does (ENG-374).
///
/// The breadcrumb, the action menu and the quick actions all ask this getter.
/// Routing it through `recordingPendencies` means the pill, the sheet and the
/// rest of the screen can never disagree about whether a recording still needs
/// classifying.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity_classification.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';

void main() {
  LocalRecordingEntity recording({
    String? serverId,
    String genreId = 'genre-1',
    String? registerId = 'reg-1',
    List<ReviewFlag> reviewFlags = const [],
  }) => LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: genreId,
    registerId: registerId,
    durationSeconds: 10,
    fileSizeBytes: 100,
    format: 'm4a',
    localFilePath: '/a.m4a',
    uploadStatus: serverId == null ? 'local' : 'uploaded',
    serverId: serverId,
    cleaningStatus: 'none',
    recordedAt: DateTime.utc(2026),
    createdAt: DateTime.utc(2026),
    retryCount: 0,
    uploadedBytes: 0,
    reviewFlags: reviewFlags,
  );

  test('an unclassified recording reads as unclassified before upload', () {
    expect(
      recording(genreId: 'unclassified', registerId: null).isUnclassified,
      isTrue,
    );
  });

  test('and still reads that way after it uploads', () {
    // Uploading writes serverId and leaves the row's flags empty. The answer
    // must not change just because the recording now exists on the server.
    expect(
      recording(
        serverId: 'srv-1',
        genreId: 'unclassified',
        registerId: null,
      ).isUnclassified,
      isTrue,
    );
  });

  test('a classified recording reads as classified even while the server '
      'still carries a stale flag', () {
    final entity = recording(
      serverId: 'srv-1',
      reviewFlags: const [
        ReviewFlag(code: 'missing_classification', origin: 'system'),
      ],
    );

    expect(entity.isUnclassified, isFalse);
  });

  test('a missing register alone leaves it unclassified', () {
    expect(recording(registerId: null).isUnclassified, isTrue);
  });
}
