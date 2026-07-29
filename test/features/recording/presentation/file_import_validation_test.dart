import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/recording/presentation/file_import_entry.dart';
import 'package:oral_collector/features/recording/presentation/file_import_validation.dart';

const _genres = [
  Genre(id: 'genre-1', name: 'Tale'),
  Genre(
    id: 'genre-2',
    name: 'Song',
    subcategories: [Subcategory(id: 'sub-1', genreId: 'genre-2', name: 'Lull')],
  ),
];

FileImportEntry _entry({
  String id = 'e1',
  String fileName = 'e1.m4a',
  String? genreId = 'genre-1',
  String? subcategoryId,
  String? registerId = 'reg-1',
  String description = 'A grandmother telling the flood story at dusk.',
}) => FileImportEntry(
  id: id,
  path: '/tmp/$fileName',
  fileName: fileName,
  sizeBytes: 1024,
  format: 'm4a',
  durationSeconds: 12,
  genreId: genreId,
  subcategoryId: subcategoryId,
  registerId: registerId,
  initialDescription: description,
);

void main() {
  group('isImportEntryValid', () {
    test('rejects an entry whose description is too short', () {
      final entry = _entry(description: 'Short one');

      expect(isImportEntryValid(entry, _genres), isFalse);
    });

    test('rejects an entry with no description at all', () {
      final entry = _entry(description: '   ');

      expect(isImportEntryValid(entry, _genres), isFalse);
    });

    test('accepts an entry once the description is long enough', () {
      final entry = _entry(description: 'Short one');
      entry.descriptionController.text =
          'Grandmother Ama retelling the flood story at dusk.';

      expect(isImportEntryValid(entry, _genres), isTrue);
    });

    test('flags only the entries whose description falls short', () {
      final ok = _entry(id: 'ok', fileName: 'ok.m4a');
      final short = _entry(
        id: 'short',
        fileName: 'short.m4a',
        description: 'too brief',
      );

      final invalid = [
        ok,
        short,
      ].where((e) => !isImportEntryValid(e, _genres)).map((e) => e.id);

      expect(invalid, ['short']);
    });

    test('still requires genre, register and subcategory', () {
      expect(isImportEntryValid(_entry(genreId: null), _genres), isFalse);
      expect(isImportEntryValid(_entry(registerId: null), _genres), isFalse);
      expect(
        isImportEntryValid(_entry(genreId: 'genre-2'), _genres),
        isFalse,
        reason: 'genre-2 has subcategories, so one must be picked',
      );
      expect(
        isImportEntryValid(
          _entry(genreId: 'genre-2', subcategoryId: 'sub-1'),
          _genres,
        ),
        isTrue,
      );
    });
  });
}
