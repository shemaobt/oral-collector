import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/widgets/cleaning_status_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

Finder _badgeText() => find.descendant(
  of: find.byType(CleaningStatusBadge),
  matching: find.byType(Text),
);

void main() {
  final l10nEn = AppLocalizationsEn();

  testWidgets('renders nothing when status is none', (tester) async {
    await tester.pumpWidget(_wrap(const CleaningStatusBadge(status: 'none')));

    expect(_badgeText(), findsNothing);
  });

  testWidgets('renders nothing when status is unknown', (tester) async {
    await tester.pumpWidget(_wrap(const CleaningStatusBadge(status: 'bogus')));

    expect(_badgeText(), findsNothing);
  });

  testWidgets('renders label and icon when cleaned', (tester) async {
    await tester.pumpWidget(
      _wrap(const CleaningStatusBadge(status: 'cleaned')),
    );

    expect(find.text(l10nEn.cleaning_cleaned), findsOneWidget);
    expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
  });

  testWidgets('renders label and icon when needs_cleaning', (tester) async {
    await tester.pumpWidget(
      _wrap(const CleaningStatusBadge(status: 'needs_cleaning')),
    );

    expect(find.text(l10nEn.cleaning_needsCleaning), findsOneWidget);
    expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
  });
}
