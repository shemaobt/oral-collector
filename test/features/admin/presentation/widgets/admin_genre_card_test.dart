/// ENG-428: the admin category list is where a person actually sees the
/// sentinel category, and its description arrived from the server in English.
/// The card has to show it in the reader's language.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/admin/presentation/widgets/admin_genre_card.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
import 'package:oral_collector/l10n/app_localizations_pt.dart';

import '../../../../support/text_scale.dart';

void main() {
  testWidgets('the admin card shows the unclassified description translated', (
    tester,
  ) async {
    final l10n = AppLocalizationsPt();

    await pumpAtTextScale(
      tester,
      locale: const Locale('pt'),
      child: AdminGenreCard(
        genre: const Genre(
          id: kUnclassifiedGenreId,
          name: 'Unclassified',
          description: 'Recordings pending classification',
        ),
        onRefresh: () {},
      ),
    );

    expect(find.text(l10n.recording_unclassifiedDesc), findsOneWidget);
    expect(find.text('Recordings pending classification'), findsNothing);
  });
}
