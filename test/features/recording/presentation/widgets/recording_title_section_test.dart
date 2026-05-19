import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_title_section.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

const _testColors = AppColorSet(
  primary: Color(0xFF000000),
  accent: Color(0xFF111111),
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

  group('RecordingTitleSection - read mode', () {
    testWidgets('renders the title text when present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: 'My Recording',
            isEditing: false,
            controller: TextEditingController(),
            onSave: (_) {},
            onCancel: () {},
            onStartEdit: () {},
          ),
        ),
      );

      expect(find.text('My Recording'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders placeholder when title is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: null,
            isEditing: false,
            controller: TextEditingController(),
            onSave: (_) {},
            onCancel: () {},
            onStartEdit: () {},
          ),
        ),
      );

      expect(find.text(l10nEn.recording_titleEmpty), findsOneWidget);
    });

    testWidgets('renders placeholder when title is empty string', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: '',
            isEditing: false,
            controller: TextEditingController(),
            onSave: (_) {},
            onCancel: () {},
            onStartEdit: () {},
          ),
        ),
      );

      expect(find.text(l10nEn.recording_titleEmpty), findsOneWidget);
    });

    testWidgets('tapping the title triggers onStartEdit', (tester) async {
      var startEditCalls = 0;

      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: 'Tap me',
            isEditing: false,
            controller: TextEditingController(),
            onSave: (_) {},
            onCancel: () {},
            onStartEdit: () => startEditCalls++,
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(startEditCalls, 1);
    });
  });

  group('RecordingTitleSection - edit mode', () {
    testWidgets('renders a single-line TextField with save/cancel buttons', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Initial');

      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: 'Initial',
            isEditing: true,
            controller: controller,
            onSave: (_) {},
            onCancel: () {},
            onStartEdit: () {},
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Initial'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      final TextField tf = tester.widget(find.byType(TextField));
      expect(tf.maxLines, 1);
    });

    testWidgets('tapping save passes the current controller text to onSave', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Edited Title');
      String? savedValue;

      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: 'Initial',
            isEditing: true,
            controller: controller,
            onSave: (v) => savedValue = v,
            onCancel: () {},
            onStartEdit: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.check));
      await tester.pump();

      expect(savedValue, 'Edited Title');
    });

    testWidgets('tapping cancel triggers onCancel', (tester) async {
      var cancelCalls = 0;

      await tester.pumpWidget(
        _wrap(
          RecordingTitleSection(
            theme: ThemeData.light(),
            colors: _testColors,
            title: 'Initial',
            isEditing: true,
            controller: TextEditingController(text: 'Edited'),
            onSave: (_) {},
            onCancel: () => cancelCalls++,
            onStartEdit: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(cancelCalls, 1);
    });
  });
}
