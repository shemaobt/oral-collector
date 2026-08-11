// ENG-407: a cache clear that keeps unsent recordings has to say so. Announcing
// plain success over a device that freed nothing reads as a defect, and it hides
// that audio the server never received is still waiting on the phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/profile/presentation/widgets/clear_cache_snack_bar.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../../support/text_scale.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  Future<void> pumpAndTap(WidgetTester tester, int keptCount) async {
    await pumpAtTextScale(
      tester,
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showClearCacheResultSnackBar(
            ScaffoldMessenger.of(context),
            AppLocalizations.of(context),
            keptCount,
          ),
          child: const Text('trigger'),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump(); // schedule the snackbar
    await tester.pump(const Duration(milliseconds: 400)); // entry animation
  }

  testWidgets('names how many recordings stayed on the device', (tester) async {
    await pumpAndTap(tester, 2);

    expect(find.text(l10n.profile_cacheClearedKept(2)), findsOneWidget);
    // The number is the whole point: the user has to learn that two recordings
    // are still waiting, not merely that the clear finished.
    expect(find.textContaining('2'), findsOneWidget);
    expect(find.text(l10n.profile_cacheCleared), findsNothing);
  });

  testWidgets('reports plain success when nothing was kept', (tester) async {
    await pumpAndTap(tester, 0);

    expect(find.text(l10n.profile_cacheCleared), findsOneWidget);
  });
}
