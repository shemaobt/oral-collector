/// Tests for the secondary-classification picker's collision prevention
/// (ENG-72).
///
/// A secondary classification is invalid only when its full triple
/// (register, genre, subcategory) is identical to the primary triple. The
/// picker prevents rather than validates: each of the three fields hides the
/// primary's value for that field, and only when the other two already match
/// the primary. Everything else stays selectable, so legitimate pairs such as
/// (Formal, Folktale, Origin myth) + (Formal, Folktale, Trickster story) can
/// be built.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/secondary_classification_fields.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeGenreNotifier extends GenreNotifier {
  _FakeGenreNotifier(this._initial);
  final GenreState _initial;

  @override
  GenreState build() => _initial;
}

typedef _Primary = ({
  String? genreId,
  String? subcategoryId,
  String? registerId,
});

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

Widget _harness({
  required ValueNotifier<_Primary> primary,
  SecondaryValues? initial,
  ValueChanged<SecondaryValues?>? onChanged,
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
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<_Primary>(
            valueListenable: primary,
            builder: (context, value, _) => SecondaryClassificationFields(
              primaryGenreId: value.genreId,
              primarySubcategoryId: value.subcategoryId,
              primaryRegisterId: value.registerId,
              initial: initial,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

/// Opens the dropdown currently reading as [label] (its hint when empty, its
/// selected option otherwise) so its offered options can be inspected.
Future<void> _openDropdownShowing(WidgetTester tester, String label) async {
  final field = find.widgetWithText(DropdownButtonFormField<String>, label);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the genre matching the primary is not offered when the subcategory and '
    'register already match the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: null,
        registerId: null,
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(_harness(primary: primary));
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Select Genre');

      expect(find.text('Folktale'), findsNothing);
      expect(find.text('Song'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'the genre matching the primary is offered while the register differs '
    'from the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: null,
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(_harness(primary: primary));
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Select Genre');

      expect(find.text('Folktale'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'the subcategory matching the primary is not offered when the genre and '
    'register already match the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-A',
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            registerId: 'formal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Select subcategory');

      expect(find.text('Origin myth'), findsNothing);
      expect(find.text('Trickster story'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'the subcategory matching the primary is offered while the register '
    'differs from the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-A',
        registerId: 'ceremonial',
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            registerId: 'formal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Select subcategory');

      expect(find.text('Origin myth'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'the register matching the primary is not offered when the genre and '
    'subcategory already match the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-A',
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            subcategoryId: 'sub-A',
            registerId: 'ceremonial',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Ceremonial');

      expect(find.text('Formal / Official'), findsNothing);
      expect(find.text('Intimate'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'the register matching the primary is offered while the subcategory '
    'differs from the primary',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-B',
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            subcategoryId: 'sub-A',
            registerId: 'ceremonial',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openDropdownShowing(tester, 'Ceremonial');

      expect(find.text('Formal / Official'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'when a primary change would collapse the secondary onto it, only the '
    'now-hidden field is cleared and its siblings keep their values',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-B',
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);
      SecondaryValues? emitted;

      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            subcategoryId: 'sub-A',
            registerId: 'formal',
          ),
          onChanged: (values) => emitted = values,
        ),
      );
      await tester.pumpAndSettle();

      // The secondary is legitimate: same genre and register as the primary,
      // different subcategory.
      expect(find.text('Folktale'), findsOneWidget);
      expect(find.text('Origin myth'), findsOneWidget);
      expect(find.text('Formal / Official'), findsOneWidget);

      // The primary moves onto the secondary's subcategory, which would make
      // the two triples identical.
      primary.value = (
        genreId: 'g-primary',
        subcategoryId: 'sub-A',
        registerId: 'formal',
      );
      await tester.pumpAndSettle();

      expect(find.text('Formal / Official'), findsNothing);
      expect(find.text('Select register'), findsOneWidget);
      expect(find.text('Folktale'), findsOneWidget);
      expect(find.text('Origin myth'), findsOneWidget);
      expect(emitted?.registerId, isNull);
      expect(emitted?.genreId, 'g-primary');
      expect(emitted?.subcategoryId, 'sub-A');
    },
  );

  testWidgets(
    'a row whose stored secondary already equals the primary opens with only '
    'the colliding field cleared, not with fields that read blank while '
    'holding a value',
    (tester) async {
      final primary = ValueNotifier<_Primary>((
        genreId: 'g-primary',
        subcategoryId: 'sub-A',
        registerId: 'formal',
      ));
      addTearDown(primary.dispose);
      SecondaryValues? emitted;

      // A legacy row: the app can no longer build this, but the database can
      // already hold it.
      await tester.pumpWidget(
        _harness(
          primary: primary,
          initial: const SecondaryValues(
            genreId: 'g-primary',
            subcategoryId: 'sub-A',
            registerId: 'formal',
          ),
          onChanged: (values) => emitted = values,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Folktale'), findsOneWidget);
      expect(find.text('Origin myth'), findsOneWidget);
      expect(find.text('Select register'), findsOneWidget);
      expect(emitted?.genreId, 'g-primary');
      expect(emitted?.subcategoryId, 'sub-A');
      expect(emitted?.registerId, isNull);
    },
  );

  testWidgets('when the colliding secondary has no register, the genre and its '
      'subcategory are cleared together', (tester) async {
    final primary = ValueNotifier<_Primary>((
      genreId: 'g-primary',
      subcategoryId: 'sub-B',
      registerId: null,
    ));
    addTearDown(primary.dispose);
    SecondaryValues? emitted;
    var emittedCount = 0;

    await tester.pumpWidget(
      _harness(
        primary: primary,
        initial: const SecondaryValues(
          genreId: 'g-primary',
          subcategoryId: 'sub-A',
        ),
        onChanged: (values) {
          emitted = values;
          emittedCount++;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Folktale'), findsOneWidget);
    expect(find.text('Origin myth'), findsOneWidget);

    // The primary moves onto the secondary's subcategory: with no register
    // to drop, the genre and subcategory go together.
    primary.value = (
      genreId: 'g-primary',
      subcategoryId: 'sub-A',
      registerId: null,
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Genre'), findsOneWidget);
    expect(find.text('Folktale'), findsNothing);
    expect(find.text('Origin myth'), findsNothing);
    expect(find.text('Select subcategory'), findsNothing);
    expect(emittedCount, greaterThan(0));
    expect(emitted, isNull);
  });
}
