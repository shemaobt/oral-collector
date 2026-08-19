// ENG-71: the backend deduplicates POST /api/oc/recordings by
// (project_id, title), so saving a second audio under a title that already
// exists in the project used to overwrite the first one silently. The
// confirmation step now asks the server whether the typed title is taken and
// stops the save so the user can rename.
//
// The lookup is best-effort: offline or on any API failure the save has to
// proceed exactly as it did before, so a flaky server can never cost a
// recording.
//
// Driving the real StorytellerPicker bottom sheet is necessary because the
// Save handler bails out unless a storyteller is selected, and that selection
// is private widget state only reachable through the picker UI.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/storyteller/presentation/widgets/storyteller_picker.dart';
import 'package:oral_collector/features/storyteller/presentation/widgets/storyteller_tile.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _projectId = 'proj-1';

class _RecordingRepositorySpy implements LocalRecordingRepository {
  final saved = <LocalRecordingEntity>[];

  @override
  Future<void> saveRecording(LocalRecordingEntity entity) async {
    saved.add(entity);
  }

  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

/// Stands in for the dedup-aware backend: echoes the queried title back as an
/// existing recording when [taken], or fails the lookup when [failure] is set.
class _TitleLookupApiRepo implements RecordingApiRepository {
  _TitleLookupApiRepo({this.taken = false, this.failure, this.hang = false});

  final bool taken;
  final Object? failure;

  /// A connected-but-silent server: the request is accepted and simply never
  /// answered, which no error path can rescue.
  final bool hang;

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
    String? reviewFlag,
  }) async {
    if (hang) return Completer<List<ServerRecording>>().future;
    final error = failure;
    if (error != null) throw error;
    if (!taken) return const [];
    return [
      ServerRecording(
        id: 'srv-1',
        projectId: projectId,
        genreId: 'g1',
        title: title,
        durationSeconds: 5,
        fileSizeBytes: 100,
        format: 'm4a',
        uploadStatus: 'uploaded',
        cleaningStatus: 'none',
        recordedAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(
    activeProject: Project(id: _projectId, name: 'P', languageId: 'l1'),
  );
}

class _FakeProjectStorytellersNotifier extends ProjectStorytellersNotifier {
  _FakeProjectStorytellersNotifier(this._initial);

  final ProjectStorytellersState _initial;

  @override
  ProjectStorytellersState build() => _initial;

  @override
  Future<void> fetch(String projectId) async {}
}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required bool online}) : _online = online;

  final bool _online;

  @override
  SyncState build() => SyncState(isOnline: _online);

  @override
  Future<void> processQueue() async {}
}

final _storyteller = Storyteller(
  id: 'st1',
  projectId: _projectId,
  name: 'Test Storyteller',
  sex: StorytellerSex.male,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2024, 1, 1),
);

const _result = RecordingResult(
  filePath: '/tmp/oral_collector_duplicate_title_test_nonexistent.m4a',
  durationSeconds: 5.0,
  format: 'm4a',
);

ProviderContainer _container({
  required LocalRecordingRepository repo,
  required _TitleLookupApiRepo api,
  bool isOnline = true,
}) {
  return ProviderContainer(
    overrides: [
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      projectStorytellersNotifierProvider.overrideWith(
        () => _FakeProjectStorytellersNotifier(
          ProjectStorytellersState(
            projectId: _projectId,
            storytellers: [_storyteller],
          ),
        ),
      ),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(online: isOnline),
      ),
      localRecordingRepositoryProvider.overrideWithValue(repo),
      recordingApiRepositoryProvider.overrideWithValue(api),
    ],
  );
}

Widget _harness(ProviderContainer container) {
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
      home: Scaffold(
        body: ConfirmationStep(
          result: _result,
          genreId: 'g1',
          subcategoryId: null,
          genreName: 'Genre',
          subcategoryName: null,
          onReRecord: () {},
          onDiscard: () {},
          // Keeps a successful save from routing to /home (no GoRouter here).
          onSaved: () {},
        ),
      ),
    ),
  );
}

/// Fills everything the Save handler insists on before it will run: a
/// storyteller (private widget state, only reachable through the picker UI) and
/// — since ENG-354 — a description long enough to be worth storing.
Future<void> _pickStoryteller(WidgetTester tester) async {
  await tester.enterText(_descriptionField, _validDescription);
  await tester.pump();
  await tester.tap(find.byType(StorytellerPicker));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // open animation
  await tester.tap(find.byType(StorytellerTile).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // close animation
  await tester.pump(); // resume _open() -> onChanged -> setState
  await tester.pump(); // rebuild with Save enabled
}

ElevatedButton _saveButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

Finder get _titleField => find.byType(TextField).first;
Finder get _descriptionField => find.byType(TextField).last;

const _validDescription = 'A folk tale about the river spirits.';

Future<void> _pickStorytellerAndSave(WidgetTester tester) async {
  await _pickStoryteller(tester);

  // _save awaits real file I/O and the title lookup, which only advance inside
  // runAsync; run the whole tap there, then pump to render the resulting UI.
  await tester.runAsync(() async {
    await tester.tap(find.byType(ElevatedButton));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    // ConfirmationStep reads its saved draft from SharedPreferences on mount
    // (ENG-518); without a mock store the plugin channel throws.
    SharedPreferences.setMockInitialValues({});
    // ConfirmationStep plus an open bottom sheet overflows the 800x600 default
    // viewport; give it room so layout exceptions don't mask the real check.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      400 * 3.0,
      1200 * 3.0,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('warns and does not save when the title is already used', (
    tester,
  ) async {
    final repo = _RecordingRepositorySpy();
    final container = _container(
      repo: repo,
      api: _TitleLookupApiRepo(taken: true),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStorytellerAndSave(tester);

    expect(find.textContaining('already exists'), findsOneWidget);
    expect(repo.saved, isEmpty);

    // Save stays available so the user can rename and try again.
    final saveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('being offline never blocks the save', (tester) async {
    // The server would answer "taken", but offline the lookup is skipped
    // entirely: no round trip can happen, and losing the recording to a check
    // that cannot run would be far worse than a late 409.
    final repo = _RecordingRepositorySpy();
    final container = _container(
      repo: repo,
      api: _TitleLookupApiRepo(taken: true),
      isOnline: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStorytellerAndSave(tester);

    expect(repo.saved, hasLength(1));
    expect(find.textContaining('already exists'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('saves anyway when the title lookup fails', (tester) async {
    final repo = _RecordingRepositorySpy();
    final container = _container(
      repo: repo,
      api: _TitleLookupApiRepo(failure: Exception('offline')),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStorytellerAndSave(tester);

    expect(repo.saved, hasLength(1));
    expect(find.text('Recording saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('a server that never answers does not block the save', (
    tester,
  ) async {
    final repo = _RecordingRepositorySpy();
    final container = _container(
      repo: repo,
      api: _TitleLookupApiRepo(hang: true),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStoryteller(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(repo.saved, isEmpty, reason: 'the lookup is still in flight');

    // Nothing will ever complete the lookup, so it has to give up on its own.
    await tester.pump(const Duration(seconds: 31));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump();

    expect(repo.saved, hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  // The local half of the same protection: the titles already stored on this
  // device are compared while the user types, so the clash surfaces inline —
  // and offline, where the server lookup above can never answer.
  group('titles already stored on this device', () {
    late AppDatabase db;
    late LocalRecordingRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = LocalRecordingRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seed(String title, {String projectId = _projectId}) =>
        repo.saveRecording(
          LocalRecordingEntity(
            id: 'local-$projectId-$title',
            projectId: projectId,
            genreId: 'g1',
            title: title,
            durationSeconds: 5,
            fileSizeBytes: 10,
            format: 'm4a',
            localFilePath: '/tmp/seeded.m4a',
            uploadStatus: 'local',
            cleaningStatus: 'none',
            recordedAt: DateTime(2026, 1, 1),
            createdAt: DateTime(2026, 1, 1),
            retryCount: 0,
            uploadedBytes: 0,
          ),
        );

    Future<void> pumpReady(WidgetTester tester) async {
      final container = _container(repo: repo, api: _TitleLookupApiRepo());
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(_harness(container));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await _pickStoryteller(tester);
    }

    testWidgets('blocks the save while the typed title is already used', (
      tester,
    ) async {
      await seed('Taken');
      await pumpReady(tester);

      await tester.enterText(_titleField, 'Taken');
      await tester.pump();

      expect(find.text('Name already used'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('a trailing space does not sneak a taken title past', (
      tester,
    ) async {
      // The save persists the resolved (trimmed) title, so the inline check has
      // to judge that same string — otherwise "Taken " passes and then collides.
      await seed('Taken');
      await pumpReady(tester);

      await tester.enterText(_titleField, 'Taken ');
      await tester.pump();

      expect(find.text('Name already used'), findsOneWidget);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('clears the warning once the title is free again', (
      tester,
    ) async {
      await seed('Taken');
      await pumpReady(tester);

      await tester.enterText(_titleField, 'Taken');
      await tester.pump();
      await tester.enterText(_titleField, 'Something else');
      await tester.pump();

      expect(find.text('Name already used'), findsNothing);
      expect(_saveButton(tester).onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('a title used in another project does not block the save', (
      tester,
    ) async {
      await seed('Taken', projectId: 'other-project');
      await pumpReady(tester);

      await tester.enterText(_titleField, 'Taken');
      await tester.pump();

      expect(find.text('Name already used'), findsNothing);
      expect(_saveButton(tester).onPressed, isNotNull);

      await tester.runAsync(() async {
        await tester.tap(find.byType(ElevatedButton));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      final stored = await repo.getAllRecordings(_projectId);
      expect(stored.map((r) => r.title), contains('Taken'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
