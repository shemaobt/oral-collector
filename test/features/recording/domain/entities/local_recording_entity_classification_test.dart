/// `isUnclassified` answers from the same place the guided flow does (ENG-374).
///
/// The breadcrumb, the action menu and the quick actions all ask this getter.
/// Routing it through `recordingPendencies` means the pill, the sheet and the
/// rest of the screen can never disagree about whether a recording still needs
/// classifying — including on who decides: the server once it knows the
/// recording, the local columns until then (ENG-379).
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

  test('and still reads that way after it uploads, because the flags came '
      'back with it', () {
    // Uploading writes serverId, and from that moment the stored flags answer
    // (ENG-379). The upload stores what the server sent back, so the answer
    // does not change just because the recording now exists on the server.
    expect(
      recording(
        serverId: 'srv-1',
        genreId: 'unclassified',
        registerId: null,
        reviewFlags: const [
          ReviewFlag(code: 'missing_classification', origin: 'system'),
        ],
      ).isUnclassified,
      isTrue,
    );
  });

  test('a recording the server still flags needs classifying, whatever the '
      'local columns hold', () {
    // ENG-379 turned this around: the server recomputes on every write and the
    // row stores the answer, so filled-in local columns cannot overrule a flag
    // that is still open.
    final entity = recording(
      serverId: 'srv-1',
      reviewFlags: const [
        ReviewFlag(code: 'missing_classification', origin: 'system'),
      ],
    );

    expect(entity.isUnclassified, isTrue);
  });

  test('a recording the server has stopped flagging is classified', () {
    expect(recording(serverId: 'srv-1').isUnclassified, isFalse);
  });

  test('a missing register alone leaves it unclassified', () {
    expect(recording(registerId: null).isUnclassified, isTrue);
  });
}
