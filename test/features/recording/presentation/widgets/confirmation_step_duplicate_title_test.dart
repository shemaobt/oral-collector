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
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

const _projectId = 'proj-1';

class _RecordingRepositorySpy implements LocalRecordingRepository {
  final saved = <LocalRecordingEntity>[];

  @override
  Future<void> saveRecording(LocalRecordingEntity entity) async {
    saved.add(entity);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

/// Stands in for the dedup-aware backend: echoes the queried title back as an
/// existing recording when [taken], or fails the lookup when [failure] is set.
class _TitleLookupApiRepo implements RecordingApiRepository {
  _TitleLookupApiRepo({this.taken = false, this.failure});

  final bool taken;
  final Object? failure;

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
  }) async {
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
  @override
  SyncState build() => const SyncState(isOnline: true);

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
  required _RecordingRepositorySpy repo,
  required _TitleLookupApiRepo api,
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
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
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

Future<void> _pickStorytellerAndSave(WidgetTester tester) async {
  await tester.tap(find.byType(StorytellerPicker));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // open animation
  await tester.tap(find.byType(StorytellerTile).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // close animation
  await tester.pump(); // resume _open() -> onChanged -> setState
  await tester.pump(); // rebuild with Save enabled

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
}
