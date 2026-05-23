import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/widgets/edit_recording_details_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

Widget _hostApp({
  required String initialTitle,
  required String initialDescription,
  required void Function(EditRecordingDetailsResult?) onResult,
  required VoidCallback onDone,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await showEditRecordingDetailsSheet(
                context,
                initialTitle: initialTitle,
                initialDescription: initialDescription,
              );
              onResult(result);
              onDone();
            },
            child: const Text('Go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final l10nEn = AppLocalizationsEn();

  testWidgets('prefills inputs with initial values', (tester) async {
    EditRecordingDetailsResult? captured;
    var done = false;

    await tester.pumpWidget(
      _hostApp(
        initialTitle: 'Hello',
        initialDescription: 'World',
        onResult: (r) => captured = r,
        onDone: () => done = true,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);

    expect(done, isFalse);
    expect(captured, isNull);
  });

  testWidgets('Save returns the updated title and description', (tester) async {
    EditRecordingDetailsResult? captured;
    var done = false;

    await tester.pumpWidget(
      _hostApp(
        initialTitle: 'Old',
        initialDescription: 'Old desc',
        onResult: (r) => captured = r,
        onDone: () => done = true,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'New title');
    await tester.enterText(find.byType(TextField).last, 'New desc');

    await tester.tap(find.text(l10nEn.recording_saveChanges));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(captured, isNotNull);
    expect(captured!.title, 'New title');
    expect(captured!.description, 'New desc');
  });

  testWidgets('Cancel returns null', (tester) async {
    EditRecordingDetailsResult? captured;
    var done = false;

    await tester.pumpWidget(
      _hostApp(
        initialTitle: 'X',
        initialDescription: 'Y',
        onResult: (r) => captured = r,
        onDone: () => done = true,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.common_cancel));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(captured, isNull);
  });

  testWidgets('Save with empty title blocks pop and shows error', (
    tester,
  ) async {
    EditRecordingDetailsResult? captured;
    var done = false;

    await tester.pumpWidget(
      _hostApp(
        initialTitle: 'Old',
        initialDescription: '',
        onResult: (r) => captured = r,
        onDone: () => done = true,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.text(l10nEn.recording_saveChanges));
    await tester.pumpAndSettle();

    expect(done, isFalse, reason: 'sheet should still be open');
    expect(captured, isNull);
    expect(find.text(l10nEn.recording_titleRequired), findsOneWidget);
  });
}
