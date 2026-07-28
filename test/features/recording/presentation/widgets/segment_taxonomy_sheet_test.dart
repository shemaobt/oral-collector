/// Tests for SegmentTaxonomySheet's collision prevention (ENG-72).
///
/// The trim editor opens this sheet to let the user override a segment's
/// primary classification (genre, subcategory, register). Domain invariant:
/// the segment's *effective* primary triple — its overrides falling back to
/// the parent's values — cannot be identical to the secondary triple it
/// inherits from the parent, because the server enforces
/// `secondary != primary` and would reject the upload with a 422. Sharing one
/// or two fields with the parent's secondary is legitimate.
///
/// The sheet prevents rather than validates: it hides the one option that
/// would complete an identical triple, so save is always available.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/segment_taxonomy_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeGenreNotifier extends GenreNotifier {
  _FakeGenreNotifier(this._initial);
  final GenreState _initial;

  @override
  GenreState build() => _initial;
}

final _genres = [
  const Genre(
    id: 'g-primary',
    name: 'Folktale',
    subcategories: [
      Subcategory(id: 'sub-A', genreId: 'g-primary', name: 'Origin myth'),
      Subcategory(id: 'sub-B', genreId: 'g-primary', name: 'Trickster story'),
    ],
  ),
  const Genre(
    id: 'g-secondary',
    name: 'Song',
    subcategories: [
      Subcategory(id: 'sub-S1', genreId: 'g-secondary', name: 'Lullaby'),
      Subcategory(id: 'sub-S2', genreId: 'g-secondary', name: 'Work song'),
    ],
  ),
];

Widget _harness({
  required String parentGenreId,
  String? parentSubcategoryId,
  String? parentRegisterId,
  String? parentSecondaryGenreId,
  String? parentSecondarySubcategoryId,
  String? parentSecondaryRegisterId,
  String? initialGenreId,
  String? initialSubcategoryId,
  String? initialRegisterId,
}) {
  return ProviderScope(
    overrides: [
      genreNotifierProvider.overrideWith(
        () => _FakeGenreNotifier(GenreState(genres: _genres)),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: SegmentTaxonomySheet(
            parentGenreId: parentGenreId,
            parentSubcategoryId: parentSubcategoryId,
            parentRegisterId: parentRegisterId,
            parentSecondaryGenreId: parentSecondaryGenreId,
            parentSecondarySubcategoryId: parentSecondarySubcategoryId,
            parentSecondaryRegisterId: parentSecondaryRegisterId,
            initialGenreId: initialGenreId,
            initialSubcategoryId: initialSubcategoryId,
            initialRegisterId: initialRegisterId,
          ),
        ),
      ),
    ),
  );
}

Future<void> _tapOption(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the parent secondary genre is not offered when the segment already '
    'matches the secondary subcategory and register',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-secondary',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Song'), findsNothing);
      expect(find.text('Folktale'), findsOneWidget);
    },
  );

  testWidgets(
    'the parent secondary genre stays offered while the segment subcategory '
    'differs from the secondary subcategory',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSubcategoryId: 'sub-A',
          parentSecondaryGenreId: 'g-secondary',
          parentSecondarySubcategoryId: 'sub-S1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Song'), findsOneWidget);
    },
  );

  testWidgets(
    'the parent secondary genre stays hidden under a subcategory override, '
    'because picking a genre drops that override',
    (tester) async {
      // The parent's secondary differs from its primary only in the register,
      // so the segment reaches the secondary triple by overriding the register.
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSubcategoryId: 'sub-A',
          parentRegisterId: 'formal',
          parentSecondaryGenreId: 'g-primary',
          parentSecondarySubcategoryId: 'sub-A',
          parentSecondaryRegisterId: 'ceremonial',
        ),
      );
      await tester.pumpAndSettle();

      // Overriding the subcategory frees the secondary register.
      expect(find.text('Ceremonial'), findsNothing);
      await _tapOption(tester, 'Trickster story');
      await _tapOption(tester, 'Ceremonial');

      // Picking Folktale would drop the subcategory override and land back on
      // the inherited sub-A, completing the secondary triple.
      expect(find.text('Folktale'), findsNothing);
    },
  );

  testWidgets(
    'the parent secondary subcategory is not offered when the segment already '
    'matches the secondary genre and register',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-primary',
          parentSecondarySubcategoryId: 'sub-A',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Origin myth'), findsNothing);
      expect(find.text('Trickster story'), findsOneWidget);
    },
  );

  testWidgets(
    'the parent secondary register is not offered when the segment already '
    'matches the secondary genre and subcategory',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-primary',
          parentSecondaryRegisterId: 'ceremonial',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ceremonial'), findsNothing);
      expect(find.text('Intimate'), findsOneWidget);
    },
  );

  testWidgets(
    'the parent secondary register stays offered while the segment genre '
    'differs from the secondary genre',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-secondary',
          parentSecondaryRegisterId: 'ceremonial',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ceremonial'), findsOneWidget);
    },
  );

  testWidgets(
    'a segment may take the parent secondary genre, which then hides only the '
    'secondary subcategory (ENG-72)',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSubcategoryId: 'sub-A',
          parentSecondaryGenreId: 'g-secondary',
          parentSecondarySubcategoryId: 'sub-S1',
        ),
      );
      await tester.pumpAndSettle();

      await _tapOption(tester, 'Song');

      expect(find.text('Lullaby'), findsNothing);
      expect(find.text('Work song'), findsOneWidget);
    },
  );

  testWidgets('a parent without any secondary classification hides nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(parentGenreId: 'g-primary'));
    await tester.pumpAndSettle();

    expect(find.text('Folktale'), findsOneWidget);
    expect(find.text('Song'), findsOneWidget);

    await _tapOption(tester, 'Song');

    expect(find.text('Lullaby'), findsOneWidget);
    expect(find.text('Work song'), findsOneWidget);
  });
}
