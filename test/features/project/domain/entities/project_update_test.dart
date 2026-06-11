import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project_update.dart';

void main() {
  group('ProjectUpdate.toJson', () {
    test('includes only name when only name is set', () {
      expect(const ProjectUpdate(name: 'New').toJson(), {'name': 'New'});
    });

    test('includes description when set', () {
      expect(const ProjectUpdate(description: 'Desc').toJson(), {
        'description': 'Desc',
      });
    });

    test('sends an explicit null to clear the description', () {
      expect(const ProjectUpdate(clearDescription: true).toJson(), {
        'description': null,
      });
    });

    test('clearDescription wins over a provided description', () {
      expect(
        const ProjectUpdate(description: 'ignored', clearDescription: true)
            .toJson(),
        {'description': null},
      );
    });

    test('includes both fields when both changed', () {
      expect(const ProjectUpdate(name: 'N', description: 'D').toJson(), {
        'name': 'N',
        'description': 'D',
      });
    });

    test('omits untouched fields and reports empty', () {
      const update = ProjectUpdate();
      expect(update.toJson(), isEmpty);
      expect(update.isEmpty, isTrue);
    });
  });
}
