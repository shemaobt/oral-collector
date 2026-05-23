/// Tests for SegmentTaxonomySheet primary-vs-secondary collision validation.
///
/// The trim editor opens this sheet to let the user override a segment's
/// primary classification (genre, subcategory, register). Domain invariant:
/// the chosen primary cannot equal the parent recording's already-set
/// secondary classification of the same kind, because the server enforces
/// `secondary != primary` and would reject the upload with a 422. The sheet
/// must block save when the user picks a colliding value and show an inline
/// explanation.
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
      home: Scaffold(
        body: SegmentTaxonomySheet(
          parentGenreId: parentGenreId,
          parentSecondaryGenreId: parentSecondaryGenreId,
          parentSecondarySubcategoryId: parentSecondarySubcategoryId,
          parentSecondaryRegisterId: parentSecondaryRegisterId,
          initialGenreId: initialGenreId,
          initialSubcategoryId: initialSubcategoryId,
          initialRegisterId: initialRegisterId,
        ),
      ),
    ),
  );
}

Finder _saveButtonFinder() => find.widgetWithText(FilledButton, 'Save');

bool _isSaveEnabled(WidgetTester tester) {
  final button = tester.widget<FilledButton>(_saveButtonFinder());
  return button.onPressed != null;
}

void main() {
  testWidgets(
    'save is enabled when the user has not changed anything from the inherit defaults',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-secondary',
        ),
      );
      await tester.pumpAndSettle();
      expect(_isSaveEnabled(tester), isTrue);
    },
  );

  testWidgets(
    'save is disabled when the user selects a primary genre that equals the '
    'parent secondary genre',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-secondary',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      expect(_isSaveEnabled(tester), isFalse);
    },
  );

  testWidgets(
    'shows an inline error message when the selected primary genre collides '
    'with the parent secondary genre',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-secondary',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('secondary', findRichText: true),
        findsAtLeastNWidgets(1),
      );
    },
  );

  testWidgets('save re-enables after the user picks a non-colliding genre', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        parentGenreId: 'g-primary',
        parentSecondaryGenreId: 'g-secondary',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Song'));
    await tester.pumpAndSettle();
    expect(_isSaveEnabled(tester), isFalse);

    await tester.tap(find.text('Folktale'));
    await tester.pumpAndSettle();
    expect(_isSaveEnabled(tester), isTrue);
  });

  testWidgets(
    'save is disabled when the selected primary subcategory equals the '
    'parent secondary subcategory (under the same genre)',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryGenreId: 'g-primary',
          parentSecondarySubcategoryId: 'sub-A',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Origin myth'));
      await tester.pumpAndSettle();

      expect(_isSaveEnabled(tester), isFalse);
    },
  );

  testWidgets(
    'save is disabled when the selected register equals the parent secondary '
    'register',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          parentGenreId: 'g-primary',
          parentSecondaryRegisterId: 'ceremonial',
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ceremonial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ceremonial'));
      await tester.pumpAndSettle();

      expect(_isSaveEnabled(tester), isFalse);
    },
  );

  testWidgets(
    'parent without any secondary classification: any primary selection is valid',
    (tester) async {
      await tester.pumpWidget(_harness(parentGenreId: 'g-primary'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Song'));
      await tester.pumpAndSettle();

      expect(_isSaveEnabled(tester), isTrue);
    },
  );
}
