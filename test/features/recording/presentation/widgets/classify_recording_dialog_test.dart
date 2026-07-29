/// Tests for [ClassifyRecordingDialog]'s secondary-classification gate
/// (ENG-72).
///
/// The dialog used to reject any secondary sharing the primary's genre. Only
/// an identical (register, genre, subcategory) triple is a collision, so a
/// secondary under the same genre but a different subcategory must be
/// classifiable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/classify_recording_dialog.dart';
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
];

Widget _harness({void Function(ClassifyResult?)? onResult}) {
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
              final result = await showDialog<ClassifyResult>(
                context: context,
                builder: (_) => const ClassifyRecordingDialog(),
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

/// The dialog stacks its dropdowns in a fixed order: primary genre,
/// primary subcategory, primary register, then the alternative section's
/// genre, subcategory and register.
Future<void> _pickFromDropdown(
  WidgetTester tester,
  int index,
  String option,
) async {
  final field = find.byType(DropdownButtonFormField<String>).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

bool _isClassifyEnabled(WidgetTester tester, AppLocalizations l10n) {
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, l10n.classify_action),
  );
  return button.onPressed != null;
}

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets(
    'Classify is enabled for a secondary sharing the primary genre but with a '
    'different subcategory',
    (tester) async {
      ClassifyResult? captured;
      await tester.pumpWidget(_harness(onResult: (r) => captured = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await _pickFromDropdown(tester, 0, 'Folktale');
      await _pickFromDropdown(tester, 1, 'Origin myth');
      await _pickFromDropdown(tester, 2, 'Formal / Official');

      await tester.tap(find.text(l10n.classify_addAlternativeTitle));
      await tester.pumpAndSettle();

      await _pickFromDropdown(tester, 3, 'Folktale');
      await _pickFromDropdown(tester, 4, 'Trickster story');
      await _pickFromDropdown(tester, 5, 'Formal / Official');

      expect(_isClassifyEnabled(tester, l10n), isTrue);

      await tester.tap(find.text(l10n.classify_action));
      await tester.pumpAndSettle();

      expect(captured?.genreId, 'g-primary');
      expect(captured?.subcategoryId, 'sub-A');
      expect(captured?.secondaryGenreId, 'g-primary');
      expect(captured?.secondarySubcategoryId, 'sub-B');
      expect(captured?.secondaryRegisterId, 'formal');
    },
  );
}
