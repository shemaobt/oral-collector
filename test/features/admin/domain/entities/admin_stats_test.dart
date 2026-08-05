import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/admin/domain/entities/admin_stats.dart';

void main() {
  group('AdminStats.fromJson', () {
    test('parseia todos os campos de um payload bem-formado', () {
      final stats = AdminStats.fromJson(<String, dynamic>{
        'total_projects': 3,
        'total_languages': 4,
        'total_recordings': 10,
        'total_duration_seconds': 7200.0,
        'active_users': 5,
      });

      expect(stats.totalProjects, 3);
      expect(stats.totalLanguages, 4);
      expect(stats.totalRecordings, 10);
      expect(stats.totalDurationSeconds, 7200.0);
      expect(stats.activeUsers, 5);
      expect(stats.totalHours, closeTo(2, 1e-9));
    });

    test('campos ausentes ou null assumem 0', () {
      expect(AdminStats.fromJson(<String, dynamic>{}).totalProjects, 0);

      final withNulls = AdminStats.fromJson(<String, dynamic>{
        'total_projects': null,
        'total_duration_seconds': null,
      });
      expect(withNulls.totalProjects, 0);
      expect(withNulls.totalDurationSeconds, 0);
    });

    test('campo numérico de tipo errado lança ParseException capturável', () {
      expect(
        () => AdminStats.fromJson(<String, dynamic>{'total_projects': 'oops'}),
        throwsA(
          isA<ParseException>().having(
            (e) => e.field,
            'field',
            'total_projects',
          ),
        ),
      );

      expect(
        () => AdminStats.fromJson(<String, dynamic>{
          'total_duration_seconds': 'oops',
        }),
        throwsA(
          isA<ParseException>().having(
            (e) => e.field,
            'field',
            'total_duration_seconds',
          ),
        ),
      );
    });
  });
}
