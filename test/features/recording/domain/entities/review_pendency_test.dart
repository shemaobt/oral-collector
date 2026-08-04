/// What a recording still owes, as the screens ask it (ENG-374).
///
/// The server is the authority once a recording exists there. A recording this
/// device made and has not uploaded has no server opinion at all, and the app
/// answers for it from the fields themselves — otherwise a recording captured
/// minutes ago would read as a complete ficha while the person who made it is
/// standing right there, which is the moment the feature is for.
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
    test('uploading an unclassified recording does not clear its pendency', () {
      // The regression that matters. Uploading writes serverId and nothing
      // else, so the row's flags stay empty while the fields are still bare.
      // Reading the flags here would make the pill disappear at the exact
      // moment the upload succeeds — losing the prompt on the main flow.
      final justUploaded = recording(
        serverId: 'srv-1',
        genreId: 'unclassified',
        registerId: null,
        description: 'curta',
        storytellerId: null,
      );

      expect(recordingPendencies(justUploaded), [
        PendencyKind.classification,
        PendencyKind.description,
        PendencyKind.storyteller,
      ]);
    });

    test('a field the user just filled in stops being owed', () {
      // Nothing clears the server's flag on the local row, so a recording can
      // carry a flag for a field that is already filled. The user finished the
      // step; the step must not reopen and send them back into the editor.
      final fixed = recording(
        serverId: 'srv-1',
        storytellerId: 'st-7',
        reviewFlags: const [
          ReviewFlag(code: 'missing_storyteller', origin: 'system'),
        ],
      );

      expect(recordingPendencies(fixed), isEmpty);
    });

    test('a code this build cannot act on becomes no step', () {
      final pendencies = recordingPendencies(
        recording(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'awaiting_transcription', origin: 'system'),
          ],
        ),
      );

      // A step with no editor behind it strands the user, and the raw code is
      // wire vocabulary in front of a field worker.
      expect(pendencies, isEmpty);
    });

    test('but that code is still reportable, not swallowed', () {
      final unknown = unknownReviewCodes(
        recording(
          serverId: 'srv-1',
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
            ReviewFlag(code: 'awaiting_transcription', origin: 'system'),
          ],
        ),
      );

      // A code landing here means the server knows something this build does
      // not. Dropping it from the UI is right; losing it entirely is not.
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
      final pendencies = recordingPendencies(recording(registerId: null));

      expect(pendencies, [PendencyKind.classification]);
    });

    test('stops owing a description as soon as one is written', () {
      final short = recordingPendencies(recording(description: 'curta'));
      expect(short, [PendencyKind.description]);

      final written = recordingPendencies(
        recording(description: 'Uma descrição longa o bastante para passar'),
      );
      expect(written, isEmpty);
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
        genreId: 'unclassified',
        registerId: null,
        description: '',
        storytellerId: null,
      ),
    );

    expect(pendencies, [
      PendencyKind.classification,
      PendencyKind.description,
      PendencyKind.storyteller,
    ]);
  });
}
