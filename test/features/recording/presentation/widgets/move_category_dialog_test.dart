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

Finder _registerPicker(AppLocalizations l10n) => find.descendant(
  of: find
      .ancestor(
        of: find.text(l10n.classify_register),
        matching: find.byType(Column),
      )
      .first,
  matching: find.byType(DropdownButtonFormField<String>),
);

Finder _openMenu() => find.byType(Scrollable).last;

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _pickRegister(
  WidgetTester tester,
  AppLocalizations l10n,
  String label,
) async {
  await tester.ensureVisible(_registerPicker(l10n));
  await tester.pumpAndSettle();
  await tester.tap(_registerPicker(l10n));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: _openMenu(), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<MoveCategoryResult?> _tapMove(
  WidgetTester tester,
  AppLocalizations l10n,
  MoveCategoryResult? Function() captured,
) async {
  await tester.tap(find.text(l10n.common_move));
  await tester.pumpAndSettle();
  return captured();
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

    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<String>,
        l10n.moveCategory_selectSubcategory,
      ),
    );
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
    'a secondary sharing the primary genre is movable while the triple differs, '
    'and a register change is carried into the result (ENG-72)',
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

      // The secondary shares the primary genre and register but not its
      // subcategory, so the triples already differ. Move additionally needs an
      // edit to enable, which the register change below provides.
      final registerField = find
          .widgetWithText(DropdownButtonFormField<String>, 'Formal / Official')
          .last;
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

  group('the primary register changes through Mover (ENG-1188)', () {
    testWidgets(
      'Mover opens with the recording\'s current register selected in the '
      'Registro picker',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentPrimaryRegisterId: 'casual',
          ),
        );
        await _openDialog(tester);

        expect(
          find.descendant(
            of: _registerPicker(l10n),
            matching: find.text('Informal / Casual'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'picking Formal / Official in the Registro picker enables Mover and the '
      'result carries the new register',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        await _pickRegister(tester, l10n, 'Formal / Official');

        expect(_isMoveEnabled(tester, l10n), isTrue);
        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.registerId, 'formal');
        expect(result?.genreId, 'g-primary');
        expect(result?.subcategoryId, 'sub-A');
      },
    );

    testWidgets(
      'moving without touching the register leaves the register out of the '
      'result',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentPrimaryRegisterId: 'casual',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        await tester.tap(find.text('Folktale'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Song').last);
        await tester.pumpAndSettle();

        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.genreId, 'g-secondary');
        expect(result?.registerId, isNull);
      },
    );

    testWidgets(
      'a primary register that completes the secondary triple clears the '
      'secondary\'s subcategory, and Mover saves',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            currentSecondaryGenreId: 'g-primary',
            currentSecondarySubcategoryId: 'sub-A',
            currentSecondaryRegisterId: 'formal',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        await _pickRegister(tester, l10n, 'Formal / Official');

        expect(_isMoveEnabled(tester, l10n), isTrue);
        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.registerId, 'formal');
        expect(result?.secondaryRegisterId, 'formal');
        expect(result?.secondaryGenreId, 'g-primary');
        expect(result?.secondarySubcategoryId, isNull);
        expect(result?.clearSecondary, isFalse);
      },
    );

    testWidgets(
      'a primary register equal to the secondary register, with a different '
      'genre or subcategory, still moves',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            currentSecondaryGenreId: 'g-primary',
            currentSecondarySubcategoryId: 'sub-B',
            currentSecondaryRegisterId: 'formal',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        await _pickRegister(tester, l10n, 'Formal / Official');

        expect(_isMoveEnabled(tester, l10n), isTrue);
        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.registerId, 'formal');
        expect(result?.secondaryRegisterId, 'formal');
        expect(result?.secondaryGenreId, 'g-primary');
        expect(result?.secondarySubcategoryId, 'sub-B');
        expect(result?.clearSecondary, isFalse);
      },
    );

    testWidgets(
      'changing only the secondary classification sends no register_id',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            currentSecondaryGenreId: 'g-secondary',
            currentSecondaryRegisterId: 'formal',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        final secondaryRegister = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Formal / Official',
        );
        await tester.ensureVisible(secondaryRegister);
        await tester.pumpAndSettle();
        await tester.tap(secondaryRegister);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: _openMenu(), matching: find.text('Ceremonial')),
        );
        await tester.pumpAndSettle();

        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.secondaryRegisterId, 'ceremonial');
        expect(result?.registerId, isNull);
      },
    );

    testWidgets(
      'a register change leaves the secondary classification untouched',
      (tester) async {
        MoveCategoryResult? captured;
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            currentSecondaryGenreId: 'g-secondary',
            currentSecondarySubcategoryId: 'sub-S1',
            currentSecondaryRegisterId: 'formal',
            onResult: (r) => captured = r,
          ),
        );
        await _openDialog(tester);

        await _pickRegister(tester, l10n, 'Consultative');

        final result = await _tapMove(tester, l10n, () => captured);
        expect(result?.secondaryGenreId, 'g-secondary');
        expect(result?.secondarySubcategoryId, 'sub-S1');
        expect(result?.secondaryRegisterId, 'formal');
        expect(result?.clearSecondary, isFalse);
      },
    );

    testWidgets(
      'the secondary fields hide the option that would complete the triple '
      'with the picked register',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            currentGenreId: 'g-primary',
            currentSubcategoryId: 'sub-A',
            currentPrimaryRegisterId: 'casual',
            currentSecondaryGenreId: 'g-primary',
            currentSecondaryRegisterId: 'formal',
          ),
        );
        await _openDialog(tester);

        final secondarySubcategory = find.widgetWithText(
          DropdownButtonFormField<String>,
          l10n.moveCategory_selectSubcategory,
        );
        Future<Finder> offeredSecondarySubcategory() async {
          await tester.ensureVisible(secondarySubcategory);
          await tester.pumpAndSettle();
          await tester.tap(secondarySubcategory);
          await tester.pumpAndSettle();
          return find.descendant(
            of: _openMenu(),
            matching: find.text('Origin myth'),
          );
        }

        expect(await offeredSecondarySubcategory(), findsOneWidget);
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        await _pickRegister(tester, l10n, 'Formal / Official');

        expect(await offeredSecondarySubcategory(), findsNothing);
      },
    );
  });
}
