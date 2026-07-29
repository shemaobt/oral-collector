import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/recording/presentation/file_import_entry.dart';
import 'package:oral_collector/features/recording/presentation/widgets/file_metadata_card.dart';
import 'package:oral_collector/features/recording/presentation/widgets/file_metadata_editor.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

const _genres = [Genre(id: 'genre-1', name: 'Tale')];

const _tooShortMessage =
    'Please describe this recording in at least 20 characters';

FileImportEntry _entry({required String id, required String description}) =>
    FileImportEntry(
      id: id,
      path: '/tmp/$id.m4a',
      fileName: '$id.m4a',
      sizeBytes: 1024,
      format: 'm4a',
      durationSeconds: 12,
      genreId: 'genre-1',
      registerId: 'reg-1',
      initialDescription: description,
    );

Widget _harness(List<FileImportEntry> entries, Set<String> errorEntryIds) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FileMetadataEditor(
          entries: entries,
          projectId: 'proj-1',
          genres: _genres,
          genresLoading: false,
          errorEntryIds: errorEntryIds,
          errorKeys: const {},
          bulkGenreId: null,
          bulkSubcategoryId: null,
          bulkRegisterId: null,
          bulkStoryteller: null,
          onBulkGenreChanged: (_) {},
          onBulkSubcategoryChanged: (_) {},
          onBulkRegisterChanged: (_) {},
          onBulkStorytellerChanged: (_) {},
          onApplyBulk: () {},
          onEntryGenreChanged: (_, _) {},
          onEntrySubcategoryChanged: (_, _) {},
          onEntryRegisterChanged: (_, _) {},
          onEntryStorytellerChanged: (_, _) {},
          onRemoveEntry: (_) {},
          isSaving: false,
          saveProgress: 0,
          hasWavFiles: false,
          compressWav: false,
          onCompressWavChanged: (_) {},
          onCancel: () {},
          onSave: () {},
          showFormatsBanner: false,
          onDismissFormatsBanner: () {},
        ),
      ),
    ),
  );
}

String? _descriptionErrorFor(WidgetTester tester, FileImportEntry entry) {
  final field = tester
      .widgetList<TextField>(find.byType(TextField))
      .firstWhere((t) => t.controller == entry.descriptionController);
  return field.decoration?.errorText;
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('file import description error', () {
    testWidgets('names only the flagged entry, not every short one', (
      tester,
    ) async {
      await _setSurface(tester, const Size(500, 1600));
      final short = _entry(id: 'short', description: 'too brief');
      // Equally short, but not flagged: the screen only flags entries when the
      // user presses save, so this one must stay silent until then.
      final notYetFlagged = _entry(id: 'quiet', description: 'also brief');

      await tester.pumpWidget(_harness([short, notYetFlagged], {'short'}));
      await tester.pump();

      expect(find.text(_tooShortMessage), findsOneWidget);

      final shortCard = find.ancestor(
        of: find.text('short.m4a'),
        matching: find.byType(FileMetadataCard),
      );
      expect(
        find.descendant(of: shortCard, matching: find.text(_tooShortMessage)),
        findsOneWidget,
      );
    });

    testWidgets('drops the message once the description is long enough', (
      tester,
    ) async {
      await _setSurface(tester, const Size(500, 1600));
      final entry = _entry(
        id: 'ok',
        description: 'Grandmother Ama retells the flood story at dusk.',
      );

      await tester.pumpWidget(_harness([entry], {'ok'}));
      await tester.pump();

      expect(find.text(_tooShortMessage), findsNothing);
    });

    testWidgets('wide layout offers a description field and flags it', (
      tester,
    ) async {
      await _setSurface(tester, const Size(1200, 1200));
      final short = _entry(id: 'short', description: 'too brief');
      final ok = _entry(
        id: 'ok',
        description: 'Grandmother Ama retells the flood story at dusk.',
      );

      await tester.pumpWidget(_harness([short, ok], {'short'}));
      await tester.pump();

      expect(_descriptionErrorFor(tester, short), _tooShortMessage);
      expect(_descriptionErrorFor(tester, ok), isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
