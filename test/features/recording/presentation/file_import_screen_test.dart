// ENG-354 review follow-up. Two claims of the file-import screen that only
// hold at the screen level, so neither the `isImportEntryValid` predicate suite
// nor the `FileMetadataEditor` widget suite can pin them:
//
//  * the description error clears while the user types, in BOTH layouts, the
//    way the confirmation step and the edit sheet already do;
//  * the save is all-or-nothing — one failing entry means nothing at all is
//    written, not "everything valid goes and the rest stays behind".
//
// The screen is driven through `initialFiles`, which is the one entry point
// that skips the file picker. The fixture is a real 44-byte PCM WAV header:
// `AudioProbe` answers that from the header alone and never reaches just_audio,
// so no platform channel is involved.
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/l10n/content_l10n.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/presentation/file_import_screen.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/recording_description.dart';

const _projectId = 'proj-1';
const _tooShort = 'Short';
const _longEnough = 'A folk tale about the river spirits, told by an elder.';

const _genre = Genre(id: 'g1', name: 'Folktale', subcategories: []);

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(
    activeProject: Project(id: _projectId, name: 'P', languageId: 'l1'),
  );
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: false);
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState(genres: [_genre]);

  @override
  Future<void> fetchGenres() async {}
}

/// Records every write the import would make, so "nothing was written" is an
/// assertion about the repository and not about the absence of a plugin.
class _RecordingRepositorySpy implements LocalRecordingRepository {
  final inserted = <LocalRecordingsCompanion>[];

  @override
  Future<void> insertRecording(LocalRecordingsCompanion companion) async {
    inserted.add(companion);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

/// A minimal 16-bit mono PCM WAV header claiming one second of audio.
Uint8List _wavBytes() {
  const sampleRate = 8000;
  const byteRate = sampleRate * 2;
  final bytes = ByteData(44);
  void ascii(int offset, String tag) {
    for (var i = 0; i < tag.length; i++) {
      bytes.setUint8(offset + i, tag.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + byteRate, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, byteRate, Endian.little);
  bytes.setUint16(32, 2, Endian.little); // block align
  bytes.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  bytes.setUint32(40, byteRate, Endian.little);
  return bytes.buffer.asUint8List();
}

/// `path` is load-bearing: the dart:io XFile derives `name` from the path and
/// ignores the `name` argument, and the import rejects an extensionless file.
XFile _audioFile(String name) =>
    XFile.fromData(_wavBytes(), path: name, name: name, mimeType: 'audio/wav');

Widget _harness(ProviderContainer container, List<XFile> files) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FileImportScreen(initialFiles: files),
    ),
  );
}

/// The description field, in either layout: the narrow card labels it, the wide
/// data table hints it, and both use the same string.
Finder _descriptionFields(String label) => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      (w.decoration?.labelText == label || w.decoration?.hintText == label),
);

Future<void> _chooseDropdownOption(
  WidgetTester tester,
  Finder dropdown,
  String option,
) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  final l10nEn = AppLocalizationsEn();
  final tooShortMessage = l10nEn.recording_descriptionTooShort(
    minDescriptionGraphemes,
  );
  final descriptionLabel = l10nEn.recording_descriptionHint;

  late _RecordingRepositorySpy repo;
  late ProviderContainer container;

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      localRecordingRepositoryProvider.overrideWithValue(repo),
    ],
  );

  void useViewport(Size size) {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = size * 3.0;
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  }

  setUp(() {
    repo = _RecordingRepositorySpy();
    container = buildContainer();
    addTearDown(container.dispose);
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  // The card list and the data table each render the description field their
  // own way, so the clearing behaviour has to be proven on both.
  for (final layout in const {
    'narrow card layout': Size(420, 1400),
    'wide table layout': Size(1200, 1000),
  }.entries) {
    testWidgets('${layout.key}: the description error clears while typing', (
      tester,
    ) async {
      useViewport(layout.value);
      await tester.pumpWidget(_harness(container, [_audioFile('story.wav')]));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, l10nEn.import_importNFiles(1)),
      );
      await tester.pumpAndSettle();
      expect(find.text(tooShortMessage), findsOneWidget);

      await tester.enterText(_descriptionFields(descriptionLabel), _longEnough);
      await tester.pump();

      expect(find.text(tooShortMessage), findsNothing);
    });
  }

  testWidgets('one short description holds back the whole batch', (
    tester,
  ) async {
    // Wide layout: the bulk bar is expanded there, so both entries can be
    // classified without opening an ExpansionTile first.
    useViewport(const Size(1200, 1000));
    await tester.pumpWidget(
      _harness(container, [_audioFile('first.wav'), _audioFile('second.wav')]),
    );
    await tester.pumpAndSettle();

    // Classify both entries in one go, so the batch differs only by
    // description and the first entry is genuinely ready to be written.
    await _chooseDropdownOption(
      tester,
      find.byType(DropdownButtonFormField<String>).first,
      localizedGenreName(l10nEn, _genre.name, id: _genre.id),
    );
    await _chooseDropdownOption(
      tester,
      find.byType(DropdownButtonFormField<String>).at(1),
      localizedRegisterName(l10nEn, 'Formal / Official'),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10nEn.import_applyToAll),
    );
    await tester.pumpAndSettle();

    final descriptions = _descriptionFields(descriptionLabel);
    await tester.enterText(descriptions.at(0), _longEnough);
    await tester.pump();
    await tester.enterText(descriptions.at(1), _tooShort);
    await tester.pump();

    await tester.tap(
      find.widgetWithText(FilledButton, l10nEn.import_importNFiles(2)),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.import_validationBanner(1)), findsOneWidget);
    expect(repo.inserted, isEmpty);
    expect(_descriptionFields(descriptionLabel), findsNWidgets(2));
  });
}
