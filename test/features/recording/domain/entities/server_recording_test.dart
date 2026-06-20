/// Tests for ServerRecording JSON parsing.
///
/// Ensures the entity carries every recording-level metadata field returned by
/// the backend so the trim editor's web/native-fallback `_loadRecording` paths
/// see the same data as the local DB. See ENG-64 and
/// `docs/recording-split-semantics.md`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'r-1',
    'project_id': 'p-1',
    'genre_id': 'g-1',
    'subcategory_id': 's-1',
    'duration_seconds': 12.5,
    'file_size_bytes': 1234,
    'format': 'm4a',
    'upload_status': 'verified',
    'cleaning_status': 'cleaned',
    'recorded_at': '2026-05-01T10:00:00.000Z',
  };

  test('parses description when present', () {
    final json = baseJson()..['description'] = 'An old story about the river';

    final rec = ServerRecording.fromJson(json);

    expect(rec.description, 'An old story about the river');
  });

  test('leaves description null when missing or null in JSON', () {
    final missing = ServerRecording.fromJson(baseJson());
    final explicitNull = ServerRecording.fromJson(
      baseJson()..['description'] = null,
    );

    expect(missing.description, isNull);
    expect(explicitNull.description, isNull);
  });

  test(
    'throws a catchable ParseException when file_size_bytes is not a num',
    () {
      final json = baseJson()..['file_size_bytes'] = 'not-a-number';

      expect(
        () => ServerRecording.fromJson(json),
        throwsA(
          isA<ParseException>().having(
            (e) => e.field,
            'field',
            'file_size_bytes',
          ),
        ),
      );
    },
  );

  test('throws a catchable ParseException when recorded_at is malformed', () {
    final json = baseJson()..['recorded_at'] = 'not-a-date';

    expect(
      () => ServerRecording.fromJson(json),
      throwsA(
        isA<ParseException>().having((e) => e.field, 'field', 'recorded_at'),
      ),
    );
  });

  test('throws a catchable ParseException when uploaded_at is malformed', () {
    final json = baseJson()..['uploaded_at'] = 'not-a-date';

    expect(
      () => ServerRecording.fromJson(json),
      throwsA(
        isA<ParseException>().having((e) => e.field, 'field', 'uploaded_at'),
      ),
    );
  });

  test(
    'throws a catchable ParseException when upload_status is not a String',
    () {
      final json = baseJson()..['upload_status'] = 5;

      expect(
        () => ServerRecording.fromJson(json),
        throwsA(
          isA<ParseException>().having(
            (e) => e.field,
            'field',
            'upload_status',
          ),
        ),
      );
    },
  );
}
