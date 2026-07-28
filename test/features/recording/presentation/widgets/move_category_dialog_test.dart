/// Characterization tests for [MoveCategoryDialog].
///
/// These lock the dialog's observable behavior at its widget boundary so the
/// ENG-206 decomposition of `_MoveCategoryDialogState.build` (a cyclomatic
/// complexity burn-down) stays behavior-preserving: every test must be green
/// before and after the refactor. The interior (private getters/sub-widgets)
/// is treated as a blackbox — only the rendered UI and the popped
/// [MoveCategoryResult] are asserted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/move_category_dialog.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

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
    ],
  ),
  const Genre(id: 'g-no-sub', name: 'Proverb'),
];

Widget _harness({
  required String currentGenreId,
  String? currentSubcategoryId,
  String? currentPrimaryRegisterId,
  String? currentSecondaryGenreId,
  String? currentSecondarySubcategoryId,
  String? currentSecondaryRegisterId,
  void Function(MoveCategoryResult?)? onResult,
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
          body: TextButton(
            onPressed: () async {
              final result = await showDialog<MoveCategoryResult>(
                context: context,
                builder: (_) => MoveCategoryDialog(
                  currentGenreId: currentGenreId,
                  currentSubcategoryId: currentSubcategoryId,
                  currentPrimaryRegisterId: currentPrimaryRegisterId,
                  currentSecondaryGenreId: currentSecondaryGenreId,
                  currentSecondarySubcategoryId: currentSecondarySubcategoryId,
                  currentSecondaryRegisterId: currentSecondaryRegisterId,
                ),
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

bool _isMoveEnabled(WidgetTester tester, AppLocalizations l10n) {
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, l10n.common_move),
  );
  return button.onPressed != null;
}

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('Move is disabled when nothing has changed', (tester) async {
    await tester.pumpWidget(_harness(currentGenreId: 'g-primary'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(_isMoveEnabled(tester, l10n), isFalse);
  });

  testWidgets(
    'selecting a different genre enables Move and pops the new genre with a '
    'cleared subcategory',
    (tester) async {
      MoveCategoryResult? captured;
      var popped = false;
      await tester.pumpWidget(
        _harness(
          currentGenreId: 'g-primary',
          currentSubcategoryId: 'sub-A',
          onResult: (r) {
            captured = r;
            popped = true;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Open the genre dropdown (its field shows the current selection) and
      // pick a different genre.
      await tester.tap(find.text('Folktale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Song').last);
      await tester.pumpAndSettle();

      expect(_isMoveEnabled(tester, l10n), isTrue);

      await tester.tap(find.text(l10n.common_move));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(captured?.genreId, 'g-secondary');
      expect(captured?.subcategoryId, isNull);
    },
  );

  testWidgets('selecting a subcategory pops it in the result', (tester) async {
    MoveCategoryResult? captured;
    await tester.pumpWidget(
      _harness(currentGenreId: 'g-primary', onResult: (r) => captured = r),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Open the subcategory dropdown (the second one) and pick a subcategory.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Origin myth').last);
    await tester.pumpAndSettle();

    expect(_isMoveEnabled(tester, l10n), isTrue);

    await tester.tap(find.text(l10n.common_move));
    await tester.pumpAndSettle();

    expect(captured?.genreId, 'g-primary');
    expect(captured?.subcategoryId, 'sub-A');
  });

  testWidgets('Cancel pops null', (tester) async {
    MoveCategoryResult? captured;
    var popped = false;
    await tester.pumpWidget(
      _harness(
        currentGenreId: 'g-primary',
        onResult: (r) {
          captured = r;
          popped = true;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(captured, isNull);
  });

  testWidgets(
    'subcategory dropdown is shown for a genre that has subcategories',
    (tester) async {
      await tester.pumpWidget(_harness(currentGenreId: 'g-primary'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.moveCategory_subcategory), findsOneWidget);
    },
  );

  testWidgets(
    'subcategory dropdown is hidden for a genre without subcategories',
    (tester) async {
      await tester.pumpWidget(_harness(currentGenreId: 'g-no-sub'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.moveCategory_subcategory), findsNothing);
    },
  );

  testWidgets(
    'a current genre absent from the list falls back to the first genre and '
    'enables Move',
    (tester) async {
      MoveCategoryResult? captured;
      await tester.pumpWidget(
        _harness(currentGenreId: 'g-deleted', onResult: (r) => captured = r),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Falls back to the first genre in the list.
      expect(find.text('Folktale'), findsOneWidget);
      // The selection changed from the (absent) current genre, so Move is live.
      expect(_isMoveEnabled(tester, l10n), isTrue);

      await tester.tap(find.text(l10n.common_move));
      await tester.pumpAndSettle();

      expect(captured?.genreId, 'g-primary');
    },
  );

  testWidgets(
    'collapsing an initially-set secondary marks clearSecondary on the result',
    (tester) async {
      MoveCategoryResult? captured;
      await tester.pumpWidget(
        _harness(
          currentGenreId: 'g-primary',
          currentSecondaryGenreId: 'g-secondary',
          onResult: (r) => captured = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The secondary section starts expanded; collapsing it clears the
      // secondary classification.
      await tester.tap(find.text(l10n.classify_addAlternativeTitle));
      await tester.pumpAndSettle();

      expect(_isMoveEnabled(tester, l10n), isTrue);

      await tester.tap(find.text(l10n.common_move));
      await tester.pumpAndSettle();

      expect(captured?.clearSecondary, isTrue);
      expect(captured?.secondaryGenreId, isNull);
    },
  );

  testWidgets(
    'a secondary under the primary genre is movable once its register differs '
    'from the primary triple (ENG-72)',
    (tester) async {
      MoveCategoryResult? captured;
      await tester.pumpWidget(
        _harness(
          currentGenreId: 'g-primary',
          currentSubcategoryId: 'sub-A',
          currentPrimaryRegisterId: 'formal',
          currentSecondaryGenreId: 'g-primary',
          currentSecondarySubcategoryId: 'sub-B',
          currentSecondaryRegisterId: 'formal',
          onResult: (r) => captured = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The secondary already shares the primary genre; changing only its
      // register keeps the two triples distinct, so Move stays available.
      final registerField = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Formal / Official',
      );
      await tester.ensureVisible(registerField);
      await tester.pumpAndSettle();
      await tester.tap(registerField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ceremonial').last);
      await tester.pumpAndSettle();

      expect(_isMoveEnabled(tester, l10n), isTrue);

      await tester.tap(find.text(l10n.common_move));
      await tester.pumpAndSettle();

      expect(captured?.secondaryGenreId, 'g-primary');
      expect(captured?.secondarySubcategoryId, 'sub-B');
      expect(captured?.secondaryRegisterId, 'ceremonial');
    },
  );
}
