// ENG-181: the admin "Genres & Subcategories" header row pairs a title with an
// add button. Under large system fonts the title must yield instead of pushing
// the row past the screen width.
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/admin/presentation/widgets/genres_section.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: GenresSection(genres: const [], onRefresh: () {}),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('header does not overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }

  testWidgets('header title stays in the tree at 2.0x', (tester) async {
    await _pump(tester, 2.0);
    expect(
      find.text(AppLocalizationsEn().admin_genresAndSubcategories),
      findsOneWidget,
    );
  });
}
