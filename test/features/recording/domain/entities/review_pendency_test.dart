/// Who decides what a recording still owes (ENG-379).
///
/// The server decides for any recording it knows about — it recomputes on every
/// write and sends the result back, and it may apply a rule this build has
/// never heard of. A recording that has never been uploaded has no server
/// answer, so its own fields answer for it; otherwise a recording captured
/// minutes ago would read as complete while the person who made it is still
/// standing there.
///
/// This only holds because the local row is kept current: the upload and every
/// edit now store the flags the server sent back. ENG-374 shipped without that
/// and had to derive locally to stay correct.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';

void main() {
  LocalRecordingEntity recording({
    String? serverId,
    String genreId = 'genre-1',
    String? registerId = 'reg-1',
    String? description = 'Uma descrição longa o bastante para o piso da regra',
    String? storytellerId = 'st-1',
    List<ReviewFlag> reviewFlags = const [],
  }) => LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: genreId,
    registerId: registerId,
    description: description,
    storytellerId: storytellerId,
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

  group('a recording the server knows about', () {
    test('owes what the server says it owes', () {
      final pendencies = recordingPendencies(
        recording(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'missing_classification', origin: 'system'),
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ],
        ),
      );

      expect(pendencies, [
        PendencyKind.classification,
        PendencyKind.storyteller,
      ]);
    });

    test(
      'stays owing after it uploads, because the flags came back with it',
      () {
        // The regression that forced ENG-374 to derive locally. Fixed at the
        // source now: the upload stores what the server returned, so the flags
        // are here to be read instead of empty.
        final justUploaded = recording(
          serverId: 'srv-1',
          genreId: 'unclassified',
          registerId: null,
          reviewFlags: const [
            ReviewFlag(code: 'missing_classification', origin: 'system'),
          ],
        );

        expect(recordingPendencies(justUploaded), [
          PendencyKind.classification,
        ]);
      },
    );

    test('stops owing once the server says the field is filled', () {
      // The edit went to the server, the server recomputed, and the response
      // was stored. An empty list is the server saying "nothing left".
      final fixed = recording(serverId: 'srv-1', storytellerId: null);

      expect(recordingPendencies(fixed), isEmpty);
    });

    test('the server outranks the local columns when they disagree', () {
      // Every local field looks bare, but the server says otherwise — it may
      // apply a rule this build predates. Following the columns here would
      // mean overruling the only party that can know.
      final pendencies = recordingPendencies(
        recording(
          serverId: 'srv-1',
          genreId: 'unclassified',
          registerId: null,
          description: '',
          storytellerId: null,
        ),
      );

      expect(pendencies, isEmpty);
    });

    test('a code this build cannot act on becomes no step', () {
      final pendencies = recordingPendencies(
        recording(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
            ReviewFlag(code: 'awaiting_transcription', origin: 'system'),
          ],
        ),
      );

      // A step with no editor behind it strands the user, and the raw code is
      // wire vocabulary in front of a field worker.
      expect(pendencies, [PendencyKind.storyteller]);
    });

    test('but that code is still reportable, not swallowed', () {
      final unknown = unknownReviewCodes(
        recording(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'awaiting_transcription', origin: 'system'),
          ],
        ),
      );

      expect(unknown, ['awaiting_transcription']);
    });
  });

  group('a recording that has never reached the server', () {
    test('owes what its own fields say it owes', () {
      final pendencies = recordingPendencies(
        recording(
          genreId: 'unclassified',
          registerId: null,
          description: 'curta',
          storytellerId: null,
        ),
      );

      expect(pendencies, [
        PendencyKind.classification,
        PendencyKind.description,
        PendencyKind.storyteller,
      ]);
    });

    test('owes nothing once its fields are filled in', () {
      expect(recordingPendencies(recording()), isEmpty);
    });

    test('a missing register alone still owes classification', () {
      expect(recordingPendencies(recording(registerId: null)), [
        PendencyKind.classification,
      ]);
    });

    test('stops owing a description as soon as one is written', () {
      expect(recordingPendencies(recording(description: 'curta')), [
        PendencyKind.description,
      ]);
      expect(
        recordingPendencies(
          recording(description: 'Uma descrição longa o bastante para passar'),
        ),
        isEmpty,
      );
    });

    test('an empty serverId counts as never sent, not as sent', () {
      // The row uses '' for absent in places, and treating that as "the server
      // knows this one" would silently answer from an empty flag list.
      final pendencies = recordingPendencies(
        recording(serverId: '', genreId: 'unclassified', registerId: null),
      );

      expect(pendencies, [PendencyKind.classification]);
    });
  });

  group('the codes the server actually sends', () {
    // These strings are the contract with the API, and the project screen
    // reaches them with nothing but a bare code from the stats aggregate — no
    // recording to fall back on. A typo here shows up as a label that silently
    // never renders, so spell each one out.
    const vocabulary = <String, PendencyKind?>{
      'missing_classification': PendencyKind.classification,
      'insufficient_description': PendencyKind.description,
      'missing_storyteller': PendencyKind.storyteller,
      'awaiting_transcription': null,
    };

    vocabulary.forEach((code, kind) {
      test('$code resolves to $kind', () {
        expect(pendencyKindForCode(code), kind);
      });
    });
  });

  test('the order is stable, so the steps do not shuffle between reads', () {
    final pendencies = recordingPendencies(
      recording(
        serverId: 'srv-1',
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ReviewFlag(code: 'missing_classification', origin: 'system'),
          ReviewFlag(code: 'insufficient_description', origin: 'system'),
        ],
      ),
    );

    // The wire order is not the reading order: the sheet numbers these steps.
    expect(pendencies, [
      PendencyKind.classification,
      PendencyKind.description,
      PendencyKind.storyteller,
    ]);
  });
}
