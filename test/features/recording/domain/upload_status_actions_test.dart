/// Which upload statuses two destructive-adjacent affordances answer to.
///
/// Both used to treat `uploading` as a failure: Retry would fire a second
/// upload over the live one, and "Clear failed" would appear — and then delete
/// — while the recording was still on its way up (ENG-46).
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

  group('hasClearableFailedUploads', () {
    test('an upload in flight is not something to clear', () {
      expect(hasClearableFailedUploads([_recording('uploading')]), isFalse);
    });

    test('a failed upload is', () {
      expect(hasClearableFailedUploads([_recording('failed')]), isTrue);
    });

    test('an empty list has nothing to clear', () {
      expect(hasClearableFailedUploads(const []), isFalse);
    });
  });
}
