import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/widgets/block_navigation_dialog.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

Widget _harness({required void Function(BuildContext) onPressed}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => onPressed(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows title, message, cancel and discard-and-leave actions in English',
    (tester) async {
      await tester.pumpWidget(
        _harness(onPressed: (ctx) => showBlockNavigationDialog(ctx)),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);
      expect(find.text(l10n.recording_blockNavMessage), findsOneWidget);
      expect(find.text(l10n.common_cancel), findsOneWidget);
      expect(find.text(l10n.recording_blockNavDiscardAndLeave), findsOneWidget);
    },
  );

  testWidgets('returns false when the user taps cancel', (tester) async {
    bool? result;

    await tester.pumpWidget(
      _harness(
        onPressed: (ctx) async {
          result = await showBlockNavigationDialog(ctx);
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('returns true when the user taps discard-and-leave', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      _harness(
        onPressed: (ctx) async {
          result = await showBlockNavigationDialog(ctx);
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsEn();
    await tester.tap(find.text(l10n.recording_blockNavDiscardAndLeave));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
