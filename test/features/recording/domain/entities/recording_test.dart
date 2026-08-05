import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/recording/domain/entities/recording.dart';

Map<String, dynamic> _json({
  Object recordedAt = '2026-01-02T03:04:05Z',
  Object uploadStatus = 'uploaded',
  bool includeCreatedAt = false,
  Object? createdAt,
}) {
  return <String, dynamic>{
    'id': 'rec_1',
    'project_id': 'proj_1',
    'genre_id': 'gen_1',
    'subcategory_id': 'sub_1',
    'user_id': 'usr_1',
    'duration_seconds': 12.5,
    'file_size_bytes': 1024,
    'format': 'm4a',
    'upload_status': uploadStatus,
    'cleaning_status': 'none',
    'recorded_at': recordedAt,
    if (includeCreatedAt) 'created_at': createdAt,
  };
}

void main() {
  group('Recording.fromJson', () {
    test('recorded_at malformado lança ParseException', () {
      expect(
        () => Recording.fromJson(_json(recordedAt: 'xx')),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'recorded_at'),
        ),
      );
    });

    test('created_at presente e malformado lança ParseException', () {
      expect(
        () =>
            Recording.fromJson(_json(includeCreatedAt: true, createdAt: 'xx')),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'created_at'),
        ),
      );
    });

    test('upload_status não-string lança ParseException', () {
      expect(
        () => Recording.fromJson(_json(uploadStatus: 5)),
        throwsA(
          isA<ParseException>().having(
            (e) => e.field,
            'field',
            'upload_status',
          ),
        ),
      );
    });

    test('recorded_at válido é parseado; created_at ausente é null', () {
      final rec = Recording.fromJson(_json());
      expect(rec.recordedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(rec.createdAt, isNull);
    });
  });
}
