import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_action_menu.dart';
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
  onPrimary: Color(0xFFFFFFFF),
  border: Color(0xFFCCCCCC),
  error: Color(0xFFAA0000),
  warning: Color(0xFFFFAA00),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

RecordingActionMenu _menu({
  required bool isUnclassified,
  required void Function(String) onPick,
}) => RecordingActionMenu(
  colors: _testColors,
  isUnclassified: isUnclassified,
  onTrim: () => onPick('trim'),
  onExport: () => onPick('export'),
  onReplace: () => onPick('replace'),
  onMove: () => onPick('move'),
  onClassify: () => onPick('classify'),
  onDelete: () => onPick('delete'),
);

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('shows nothing until the icon is tapped', (tester) async {
    await tester.pumpWidget(
      _wrap(_menu(isUnclassified: false, onPick: (_) {})),
    );

    expect(find.text(l10n.recording_splitRecording), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.moreVertical));
    await tester.pumpAndSettle();

    expect(find.text(l10n.recording_splitRecording), findsOneWidget);
  });

  testWidgets('shows the move item when classified', (tester) async {
    await tester.pumpWidget(
      _wrap(_menu(isUnclassified: false, onPick: (_) {})),
    );
    await tester.tap(find.byIcon(LucideIcons.moreVertical));
    await tester.pumpAndSettle();

    expect(find.text(l10n.recording_moveCategory), findsOneWidget);
    expect(find.text(l10n.classify_action), findsNothing);
  });

  testWidgets('shows the classify item when unclassified', (tester) async {
    await tester.pumpWidget(_wrap(_menu(isUnclassified: true, onPick: (_) {})));
    await tester.tap(find.byIcon(LucideIcons.moreVertical));
    await tester.pumpAndSettle();

    expect(find.text(l10n.classify_action), findsOneWidget);
    expect(find.text(l10n.recording_moveCategory), findsNothing);
  });

  testWidgets('selecting an item fires its callback', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _wrap(_menu(isUnclassified: false, onPick: (v) => picked = v)),
    );
    await tester.tap(find.byIcon(LucideIcons.moreVertical));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.recording_splitRecording));
    await tester.pumpAndSettle();

    expect(picked, 'trim');
  });
}
