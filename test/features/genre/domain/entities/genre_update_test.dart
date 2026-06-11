import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/domain/entities/genre_update.dart';

void main() {
  group('GenreUpdate.toJson', () {
    test('includes only name when only name is set', () {
      expect(const GenreUpdate(name: 'New').toJson(), {'name': 'New'});
    });

    test('includes description when set', () {
      expect(const GenreUpdate(description: 'Desc').toJson(), {
        'description': 'Desc',
      });
    });

    test('sends an explicit null to clear the description', () {
      expect(const GenreUpdate(clearDescription: true).toJson(), {
        'description': null,
      });
    });

    test('clearDescription wins over a provided description', () {
      expect(
        const GenreUpdate(description: 'ignored', clearDescription: true)
            .toJson(),
        {'description': null},
      );
    });

    test('omits untouched fields and reports empty', () {
      const update = GenreUpdate();
      expect(update.toJson(), isEmpty);
      expect(update.isEmpty, isTrue);
    });
  });
}
