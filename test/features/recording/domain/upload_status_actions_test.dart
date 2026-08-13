/// Which upload statuses the two retry affordances answer to.
///
/// Both used to treat `uploading` as a failure: Retry would fire a second
/// upload over the live one, and the list's bulk action would appear — and
/// then delete — while the recording was still on its way up (ENG-46).
///
/// The bulk action is no longer destructive (ENG-404) and no longer matches
/// `failed` alone. `failed_exhausted` is the status that most needs it: it left
/// the queue for good and will not be attempted again without one. The three
/// failures a bare retry cannot fix — a duplicate title, a short description, a
/// missing audio file — stay out, because each would fail the same way again
/// and each already has its own banner routing the user to the actual fix.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/upload_status_actions.dart';

LocalRecordingEntity _recording(String uploadStatus) => LocalRecordingEntity(
  id: 'rec-$uploadStatus',
  projectId: 'proj-1',
  genreId: 'genre-1',
  durationSeconds: 60,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/rec.m4a',
  uploadStatus: uploadStatus,
  cleaningStatus: 'none',
  recordedAt: DateTime.utc(2026, 1, 1),
  createdAt: DateTime.utc(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
);

void main() {
  group('canRetryUpload', () {
    const cases = <({String status, int retryCount, bool expected})>[
      (status: 'uploading', retryCount: 0, expected: false),
      (status: 'failed', retryCount: 0, expected: true),
      (status: 'failed_exhausted', retryCount: 5, expected: true),
      (status: 'local', retryCount: 0, expected: false),
      (status: 'local', retryCount: 1, expected: true),
      (status: 'uploaded', retryCount: 0, expected: false),
    ];

    for (final c in cases) {
      test('${c.status} at retryCount ${c.retryCount} -> ${c.expected}', () {
        expect(canRetryUpload(c.status, c.retryCount), c.expected);
      });
    }
  });

  group('hasRetryableFailedUploads', () {
    const offered = ['failed', 'failed_exhausted'];
    const withheld = [
      'uploading',
      'local',
      'uploaded',
      'verified',
      'failed_conflict',
      'failed_description',
      'failed_missing_file',
    ];

    for (final status in offered) {
      test('$status is worth retrying in bulk', () {
        expect(hasRetryableFailedUploads([_recording(status)]), isTrue);
      });
    }

    for (final status in withheld) {
      test('$status is not', () {
        expect(hasRetryableFailedUploads([_recording(status)]), isFalse);
      });
    }

    test('an empty list has nothing to retry', () {
      expect(hasRetryableFailedUploads(const []), isFalse);
    });

    test('one retryable failure among unretryable ones is enough', () {
      expect(
        hasRetryableFailedUploads([
          _recording('failed_conflict'),
          _recording('uploaded'),
          _recording('failed_exhausted'),
        ]),
        isTrue,
      );
    });
  });
}
