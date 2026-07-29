import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/widgets/edit_recording_details_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/recording_description.dart';

/// Comfortably past [minDescriptionGraphemes]; ENG-354 made the field required.
const _validDescription = 'A folk tale about the river spirits.';

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
    await tester.enterText(find.byType(TextField).last, _validDescription);

    await tester.tap(find.text(l10nEn.recording_saveChanges));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(captured, isNotNull);
    expect(captured!.title, 'New title');
    expect(captured!.description, _validDescription);
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
        initialDescription: _validDescription,
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

  // ENG-354: the description carries the same weight as the title now — an
  // edit may not strip a recording back down to an unusable one-liner.
  group('description is required', () {
    final tooShortMessage = l10nEn.recording_descriptionTooShort(
      minDescriptionGraphemes,
    );

    Future<void> openSheet(
      WidgetTester tester, {
      required void Function(EditRecordingDetailsResult?) onResult,
      required VoidCallback onDone,
      String initialDescription = _validDescription,
    }) async {
      await tester.pumpWidget(
        _hostApp(
          initialTitle: 'Old',
          initialDescription: initialDescription,
          onResult: onResult,
          onDone: onDone,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('Save with a too-short description blocks pop and explains', (
      tester,
    ) async {
      EditRecordingDetailsResult? captured;
      var done = false;

      await openSheet(
        tester,
        onResult: (r) => captured = r,
        onDone: () => done = true,
      );

      await tester.enterText(find.byType(TextField).last, 'Too short');
      await tester.tap(find.text(l10nEn.recording_saveChanges));
      await tester.pumpAndSettle();

      expect(done, isFalse, reason: 'sheet should still be open');
      expect(captured, isNull);
      expect(find.text(tooShortMessage), findsOneWidget);
    });

    testWidgets('Save with an emptied description blocks pop', (tester) async {
      EditRecordingDetailsResult? captured;
      var done = false;

      await openSheet(
        tester,
        onResult: (r) => captured = r,
        onDone: () => done = true,
      );

      await tester.enterText(find.byType(TextField).last, '    ');
      await tester.tap(find.text(l10nEn.recording_saveChanges));
      await tester.pumpAndSettle();

      expect(done, isFalse);
      expect(captured, isNull);
      expect(find.text(tooShortMessage), findsOneWidget);
    });

    testWidgets('lengthening the description clears the error and saves', (
      tester,
    ) async {
      EditRecordingDetailsResult? captured;
      var done = false;

      await openSheet(
        tester,
        initialDescription: '',
        onResult: (r) => captured = r,
        onDone: () => done = true,
      );

      await tester.tap(find.text(l10nEn.recording_saveChanges));
      await tester.pumpAndSettle();
      expect(find.text(tooShortMessage), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, _validDescription);
      await tester.pumpAndSettle();
      expect(find.text(tooShortMessage), findsNothing);

      await tester.tap(find.text(l10nEn.recording_saveChanges));
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(captured!.description, _validDescription);
    });
  });
}
