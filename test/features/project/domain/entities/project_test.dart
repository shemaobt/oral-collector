import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';

Map<String, dynamic> _json({bool includeCreatedAt = false, Object? createdAt}) {
  return <String, dynamic>{
    'id': 'proj_1',
    'name': 'Projeto',
    'language_id': 'lang_1',
    if (includeCreatedAt) 'created_at': createdAt,
  };
}

void main() {
  group('Project.fromJson', () {
    test('created_at presente e malformado lança ParseException', () {
      expect(
        () => Project.fromJson(_json(includeCreatedAt: true, createdAt: 'xx')),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'created_at'),
        ),
      );
    });

    test('created_at ausente é null; presente e válido é parseado', () {
      expect(Project.fromJson(_json()).createdAt, isNull);
      final p = Project.fromJson(
        _json(includeCreatedAt: true, createdAt: '2026-03-04T05:06:07Z'),
      );
      expect(p.createdAt, DateTime.utc(2026, 3, 4, 5, 6, 7));
    });
  });
}
