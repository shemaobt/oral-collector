import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_about_section.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

const _testColors = AppColorSet(
  primary: Color(0xFF000000),
  accent: Color(0xFFBE4A01),
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF222222),
  card: Color(0xFFEEEEEE),
  surfaceAlt: Color(0xFFDDDDDD),
  secondary: Color(0xFF333333),
  info: Color(0xFF444444),
  infoText: Color(0xFF555555),
  success: Color(0xFF008800),
  successText: Color(0xFF005500),
  border: Color(0xFFCCCCCC),
  error: Color(0xFFAA0000),
  warning: Color(0xFFFFAA00),
);

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Builder(builder: (_) => child)),
  );
}

void main() {
  final l10nEn = AppLocalizationsEn();

  testWidgets('renders title and description when both present', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: 'My Recording',
          description: 'A short description',
          canEdit: true,
          onEdit: () {},
        ),
      ),
    );

    expect(find.text('My Recording'), findsOneWidget);
    expect(find.text('A short description'), findsOneWidget);
  });

  testWidgets('renders title placeholder when title is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: null,
          description: null,
          canEdit: true,
          onEdit: () {},
        ),
      ),
    );

    expect(find.text(l10nEn.recording_titleEmpty), findsOneWidget);
  });

  testWidgets('renders description placeholder when description is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: 'Title',
          description: '',
          canEdit: true,
          onEdit: () {},
        ),
      ),
    );

    expect(find.text(l10nEn.recording_descriptionEmpty), findsOneWidget);
  });

  testWidgets('shows edit button when canEdit is true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: 'Title',
          description: 'Desc',
          canEdit: true,
          onEdit: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
  });

  testWidgets('hides edit button when canEdit is false', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: 'Title',
          description: 'Desc',
          canEdit: false,
          onEdit: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.pencil), findsNothing);
  });

  testWidgets('tapping edit button triggers onEdit', (tester) async {
    var editCalls = 0;

    await tester.pumpWidget(
      _wrap(
        RecordingAboutSection(
          theme: ThemeData.light(),
          colors: _testColors,
          title: 'Title',
          description: 'Desc',
          canEdit: true,
          onEdit: () => editCalls++,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pump();

    expect(editCalls, 1);
  });
}
