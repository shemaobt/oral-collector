/// The genre filter bar lists whatever `GET /api/oc/genres` returned, and that
/// includes the `unclassified` row the server seeds with the English name
/// "Unclassified". A reader on a Portuguese phone must not see it (ENG-9).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
import 'package:oral_collector/features/recording/presentation/widgets/genre_filter_bar.dart';
import 'package:oral_collector/l10n/app_localizations_pt.dart';

import '../../../../support/text_scale.dart';

/// The order the server sends: the sentinel sorts last (sort_order 9999).
const _genres = [
  Genre(id: 'gen_narrative', name: 'Narrative'),
  Genre(id: kUnclassifiedGenreId, name: 'Unclassified'),
];

void main() {
  final l10n = AppLocalizationsPt();

  testWidgets('the unclassified chip reads in the user language', (
    tester,
  ) async {
    // Wider than a phone on purpose: the bar scrolls horizontally and the
    // sentinel sorts last, so a narrow viewport could leave it unbuilt and the
    // assertion would pass for the wrong reason.
    await pumpAtTextScale(
      tester,
      locale: const Locale('pt'),
      size: const Size(900, 400),
      child: Builder(
        builder: (context) => GenreFilterBar(
          colors: AppColors.of(context),
          theme: Theme.of(context),
          genres: _genres,
          selectedGenreId: null,
          onGenreSelected: (_) {},
        ),
      ),
    );

    expect(find.text(l10n.recording_unclassified), findsOneWidget);
    expect(find.text('Unclassified'), findsNothing);
  });
}
