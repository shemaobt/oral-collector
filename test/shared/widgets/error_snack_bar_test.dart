// Behavior of the single error-presentation helper showErrorSnackBar (ENG-186):
// it maps the raw error to a friendly message once, optionally wraps it with a
// caller-supplied template, and renders the styled (alert-icon) snackbar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/widgets/error_snack_bar.dart';

import '../../support/text_scale.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  Future<void> pumpTrigger(
    WidgetTester tester,
    void Function(BuildContext context) onPressed,
  ) async {
    await pumpAtTextScale(
      tester,
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => onPressed(context),
          child: const Text('trigger'),
        ),
      ),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('trigger'));
    await tester.pump(); // schedule the snackbar
    await tester.pump(const Duration(milliseconds: 400)); // entry animation
  }

  testWidgets('renders the styled alert-icon snackbar for a typed exception', (
    tester,
  ) async {
    await pumpTrigger(
      tester,
      (context) => showErrorSnackBar(context, const ForbiddenException()),
    );

    await tapAndSettle(tester);

    expect(find.text(l10n.error_noPermission), findsOneWidget);
    expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
  });

  testWidgets('wraps the friendly message with the given template', (
    tester,
  ) async {
    await pumpTrigger(
      tester,
      (context) => showErrorSnackBar(
        context,
        const ForbiddenException(),
        template: (friendly) => 'Prefix: $friendly',
      ),
    );

    await tapAndSettle(tester);

    expect(find.text('Prefix: ${l10n.error_noPermission}'), findsOneWidget);
  });

  testWidgets('maps a raw string reason before applying the template', (
    tester,
  ) async {
    // A raw (untyped) reason must be friendly-mapped first; the template wraps
    // the MAPPED value, not the raw string. A SocketException string maps to
    // error_network, so an identity-mapping regression would fail this.
    await pumpTrigger(
      tester,
      (context) => showErrorSnackBar(
        context,
        'SocketException: failed host lookup',
        template: (f) => 'X: $f',
      ),
    );

    await tapAndSettle(tester);

    expect(find.text('X: ${l10n.error_network}'), findsOneWidget);
  });

  testWidgets(
    'share failure shows the localized prefix, not the mapped reason',
    (tester) async {
      // Mirrors recording_detail_screen's share path: AudioExporter's raw reason
      // ("File not found or empty") would friendly-map to an import message, so
      // the share path ignores it and shows only the localized prefix.
      await pumpTrigger(
        tester,
        (context) => showErrorSnackBar(
          context,
          'File not found or empty',
          template: (_) => l10n.recording_exportShareFailed,
        ),
      );

      await tapAndSettle(tester);

      expect(find.text(l10n.recording_exportShareFailed), findsOneWidget);
    },
  );
}
