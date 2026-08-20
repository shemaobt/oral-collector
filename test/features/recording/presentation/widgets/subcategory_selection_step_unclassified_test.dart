/// ENG-517: the subcategory picker is where a person meets the sentinel
/// subcategory, and its description line has to read in their language.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
import 'package:oral_collector/features/recording/presentation/widgets/subcategory_selection_step.dart';
import 'package:oral_collector/l10n/app_localizations_pt.dart';

import '../../../../support/text_scale.dart';

void main() {
  testWidgets('the picker shows the unclassified description translated', (
    tester,
  ) async {
    final l10n = AppLocalizationsPt();

    await pumpAtTextScale(
      tester,
      locale: const Locale('pt'),
      child: SubcategorySelectionStep(
        genre: const Genre(
          id: kUnclassifiedGenreId,
          name: 'Unclassified',
          subcategories: [
            Subcategory(
              id: kUnclassifiedSubcategoryId,
              genreId: kUnclassifiedGenreId,
              name: 'Unclassified',
              description: 'Default subcategory for pending classification',
            ),
          ],
        ),
        selectedSubcategoryId: null,
        onSelect: (_) {},
        onNext: () {},
      ),
    );

    expect(
      find.text(l10n.recording_unclassifiedSubcategoryDesc),
      findsOneWidget,
    );
  });
}
