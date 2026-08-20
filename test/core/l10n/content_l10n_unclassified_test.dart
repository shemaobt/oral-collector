/// The server seeds a real genre row AND a real subcategory row, both with id
/// `unclassified` and name "Unclassified" (tripod-api migration 20260415_0001),
/// and the taxonomy endpoints hand them to the app like any other row. Their
/// names have to reach the user translated, and the translation has to be
/// chosen by the id — the name is the server's to change (ENG-9). The genre's
/// description is the server's to change for the same reason, and reaches the
/// reader the same way (ENG-428). The subcategory description is chosen the
/// same way, from the id, since ENG-517.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/l10n/content_l10n.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
import 'package:oral_collector/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsPt();

  group('genre', () {
    test('the unclassified category reads in the user language', () {
      final name = localizedGenreName(
        l10n,
        'Unclassified',
        id: kUnclassifiedGenreId,
      );

      expect(name, l10n.recording_unclassified);
      expect(name, isNot('Unclassified'));
    });

    test('the unclassified category is recognised by id, not by name', () {
      final name = localizedGenreName(
        l10n,
        'Uncategorized',
        id: kUnclassifiedGenreId,
      );

      expect(name, l10n.recording_unclassified);
      expect(name, isNot('Uncategorized'));
    });

    test('a taxonomy category is still translated by name', () {
      expect(
        localizedGenreName(l10n, 'Narrative', id: 'gen_narrative'),
        l10n.genre_narrative,
      );
    });

    test(
      'an unknown category still falls back to the name the server sent',
      () {
        expect(
          localizedGenreName(l10n, 'Community Chronicle', id: 'gen_new'),
          'Community Chronicle',
        );
      },
    );

    test('an empty id does not claim to be the unclassified category', () {
      expect(
        localizedGenreName(l10n, 'Narrative', id: ''),
        l10n.genre_narrative,
      );
    });
  });

  group('genre description', () {
    test(
      'the unclassified category description reads in the user language',
      () {
        final description = localizedGenreDescription(
          l10n,
          'Recordings pending classification',
          id: kUnclassifiedGenreId,
        );

        expect(description, l10n.recording_unclassifiedDesc);
        expect(description, isNot('Recordings pending classification'));
      },
    );

    test('the unclassified description is recognised by id, not by text', () {
      final description = localizedGenreDescription(
        l10n,
        'Recordings awaiting a category',
        id: kUnclassifiedGenreId,
      );

      expect(description, l10n.recording_unclassifiedDesc);
      expect(description, isNot('Recordings awaiting a category'));
    });

    test('a taxonomy category description is still translated by text', () {
      expect(
        localizedGenreDescription(
          l10n,
          'Laws, rituals, procedures, and instructional forms',
          id: 'gen_instructional',
        ),
        l10n.genre_instructionalDesc,
      );
    });

    test(
      'an unknown description still falls back to the text the server sent',
      () {
        expect(
          localizedGenreDescription(
            l10n,
            'Chronicles kept by the community',
            id: 'gen_new',
          ),
          'Chronicles kept by the community',
        );
      },
    );
  });

  group('subcategory', () {
    test('the unclassified subcategory reads in the user language', () {
      final name = localizedSubcategoryName(
        l10n,
        'Unclassified',
        id: kUnclassifiedSubcategoryId,
      );

      expect(name, l10n.recording_unclassified);
      expect(name, isNot('Unclassified'));
    });

    test('the unclassified subcategory is recognised by id, not by name', () {
      final name = localizedSubcategoryName(
        l10n,
        'Uncategorized',
        id: kUnclassifiedSubcategoryId,
      );

      expect(name, l10n.recording_unclassified);
      expect(name, isNot('Uncategorized'));
    });

    test('a taxonomy subcategory is still translated by name', () {
      expect(
        localizedSubcategoryName(l10n, 'Genealogy', id: 'sub_genealogy'),
        l10n.sub_genealogy,
      );
    });

    test(
      'an unknown subcategory still falls back to the name the server sent',
      () {
        expect(
          localizedSubcategoryName(l10n, 'Fishing Chant', id: 'sub_new'),
          'Fishing Chant',
        );
      },
    );

    test('an empty id does not claim to be the unclassified subcategory', () {
      expect(
        localizedSubcategoryName(l10n, 'Genealogy', id: ''),
        l10n.sub_genealogy,
      );
    });
  });

  group('subcategory description', () {
    test(
      'the unclassified subcategory description reads in the user language',
      () {
        final description = localizedSubcategoryDescription(
          l10n,
          'Unclassified',
          id: kUnclassifiedSubcategoryId,
        );

        expect(description, l10n.recording_unclassifiedSubcategoryDesc);
      },
    );

    test('the unclassified subcategory description is recognised by id, not by '
        'text', () {
      final description = localizedSubcategoryDescription(
        l10n,
        'Uncategorized',
        id: kUnclassifiedSubcategoryId,
      );

      expect(description, l10n.recording_unclassifiedSubcategoryDesc);
    });

    test('a taxonomy subcategory description is still translated by text', () {
      expect(
        localizedSubcategoryDescription(l10n, 'Genealogy', id: 'sub_genealogy'),
        l10n.sub_genealogyDesc,
      );
    });

    test('an unknown subcategory still has no description at all', () {
      expect(
        localizedSubcategoryDescription(l10n, 'Fishing Chant', id: 'sub_new'),
        isNull,
      );
    });
  });
}
