import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/update_recording_request.dart';

void main() {
  group('UpdateRecordingRequest.toJson', () {
    test('omits every field when nothing is set', () {
      expect(const UpdateRecordingRequest().toJson(), isEmpty);
    });

    test('includes only the fields that are set, in snake_case', () {
      final json = const UpdateRecordingRequest(
        title: 'My title',
        description: 'A description',
        genreId: 'g-1',
        subcategoryId: 'sc-1',
        registerId: 'r-1',
        storytellerId: 'st-1',
        cleaningStatus: 'needs_cleaning',
      ).toJson();

      expect(json, {
        'title': 'My title',
        'description': 'A description',
        'genre_id': 'g-1',
        'subcategory_id': 'sc-1',
        'register_id': 'r-1',
        'storyteller_id': 'st-1',
        'cleaning_status': 'needs_cleaning',
      });
    });

    test('sends the secondary classification when provided', () {
      final json = const UpdateRecordingRequest(
        secondaryGenreId: 'g-2',
        secondarySubcategoryId: 'sc-2',
        secondaryRegisterId: 'r-2',
      ).toJson();

      expect(json, {
        'secondary_genre_id': 'g-2',
        'secondary_subcategory_id': 'sc-2',
        'secondary_register_id': 'r-2',
      });
    });

    test('omits the secondary keys that are individually null', () {
      final json = const UpdateRecordingRequest(
        secondaryGenreId: 'g-2',
      ).toJson();

      expect(json, {'secondary_genre_id': 'g-2'});
    });

    test(
      'clearSecondary sends an explicit null for all three secondary keys',
      () {
        final json = const UpdateRecordingRequest(
          clearSecondary: true,
        ).toJson();

        expect(json, {
          'secondary_genre_id': null,
          'secondary_subcategory_id': null,
          'secondary_register_id': null,
        });
      },
    );

    test('clearSecondary overrides any secondary values that were passed', () {
      final json = const UpdateRecordingRequest(
        clearSecondary: true,
        secondaryGenreId: 'g-2',
        secondarySubcategoryId: 'sc-2',
        secondaryRegisterId: 'r-2',
      ).toJson();

      expect(json, {
        'secondary_genre_id': null,
        'secondary_subcategory_id': null,
        'secondary_register_id': null,
      });
    });

    test('keeps an empty storyteller id as an explicit value', () {
      // setStoryteller(... ?? '') clears the storyteller with an empty string,
      // which must reach the wire because it is not null.
      expect(const UpdateRecordingRequest(storytellerId: '').toJson(), {
        'storyteller_id': '',
      });
    });

    test('carries the numeric replace-audio metadata', () {
      final json = const UpdateRecordingRequest(
        durationSeconds: 12.5,
        fileSizeBytes: 2048,
      ).toJson();

      expect(json, {'duration_seconds': 12.5, 'file_size_bytes': 2048});
    });
  });
}
