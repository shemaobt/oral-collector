/// ENG-518 (fatia 2): sair da tela de confirmação deixa de custar a gravação.
///
/// O comportamento sob teste é o da pessoa que precisa sair — para escrever a
/// descrição em outro aplicativo, para atender uma ligação, para trocar de aba.
/// Cada teste aciona a saída pela interface e olha duas coisas verificáveis de
/// fora: se o arquivo de áudio continua no disco, e se a gravação aparece na
/// lista de não salvas que o banner da tela inicial lê. Nenhum assert sobre
/// qual estado foi escrito na linha de sessão, nem sobre a ordem das chamadas:
/// trocar o estado reusado por outro mantém estes testes verdes desde que a
/// pessoa veja o mesmo.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_notifier.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/recovery_confirm_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/storyteller/presentation/widgets/storyteller_picker.dart';
import 'package:oral_collector/features/storyteller/presentation/widgets/storyteller_tile.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _projectId = 'proj-1';
const _sessionId = 'sess-eng518';
const _typedTitle = 'The River Spirits';
const _typedDescription =
    'A folk tale about the river spirits, told by an elder at dusk.';

const _keepForLaterLabel = 'Keep for later';
const _discardLabel = 'Discard';
const _cancelLabel = 'Cancel';

final _storyteller = Storyteller(
  id: 'st1',
  projectId: _projectId,
  name: 'Test Storyteller',
  sex: StorytellerSex.male,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2024, 1, 1),
);

class _EmptyApiRepo implements RecordingApiRepository {
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
  }) async => const [];

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
  @override
  ProjectStorytellersState build() => ProjectStorytellersState(
    projectId: _projectId,
    storytellers: [_storyteller],
  );

  @override
  Future<void> fetch(String projectId) async {}
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: false);

  @override
  Future<void> processQueue() async {}
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class _FakeRecordingSessionNotifier extends RecordingSessionNotifier {
  @override
  RecordingState build() => const RecordingState();
}

class _FakeInviteNotifier extends InviteNotifier {
  @override
  InviteState build() => const InviteState();

  @override
  Future<void> fetchInvites() async {}
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();
}

late Directory _docs;
late AppDatabase _db;
late RecordingSessionRepository _sessions;

/// Containers here are deliberately never disposed, for the reason the fatia-1
/// draft suite documents: `ConfirmationStep.dispose` clears its pending-decision
/// marker from a deferred microtask, and tearing the container down while that
/// microtask is queued throws "used after dispose".
ProviderContainer _makeContainer({PendingRecovery? pendingRecovery}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(_db),
      recoveryCoordinatorProvider.overrideWith(
        (ref) => RecoveryCoordinator(ref, directoryResolver: () async => _docs),
      ),
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      projectStorytellersNotifierProvider.overrideWith(
        _FakeProjectStorytellersNotifier.new,
      ),
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      recordingApiRepositoryProvider.overrideWithValue(_EmptyApiRepo()),
      recordingSessionNotifierProvider.overrideWith(
        _FakeRecordingSessionNotifier.new,
      ),
      inviteNotifierProvider.overrideWith(_FakeInviteNotifier.new),
      roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
    ],
  );
  if (pendingRecovery != null) {
    container.read(pendingRecoveryProvider.notifier).state = pendingRecovery;
  }
  return container;
}

/// The audio file every test hangs its verdict on: does it still exist after
/// the person leaves?
///
/// Deliberately zero bytes. `ConfirmationStep` skips loading the player for an
/// empty file, and a loaded player reaches for the just_audio platform channel
/// no widget test has. What is under test is the decision to keep or delete the
/// file, which the bytes inside it have no say in.
void _createEmptyAudioFile(String path) {
  File(path).createSync();
}

/// A recording that reached the confirmation form the way production reaches
/// it: a session row inserted at the start, anchored to the finalized audio and
/// marked completed before the form opens.
Future<RecordingResult> _seedFinishedRecording({
  String sessionId = _sessionId,
}) async {
  final segments = [SegmentPaths.forSegment(_docs.path, sessionId, 0)];
  await _sessions.insertSession(
    RecordingSessionsCompanion.insert(
      id: sessionId,
      projectId: _projectId,
      genreId: 'g1',
      startedAt: DateTime(2026, 8, 12),
      segmentPathsJson: Value(jsonEncode(segments)),
      totalDurationSeconds: const Value(5.0),
      lastSegmentIndex: const Value(0),
    ),
  );
  final audioPath = '${_docs.path}/recording_$sessionId.m4a';
  _createEmptyAudioFile(audioPath);
  await _sessions.completeWithFinalizedAudio(
    sessionId,
    filePath: audioPath,
    durationSeconds: 5.0,
  );
  return RecordingResult(
    filePath: audioPath,
    durationSeconds: 5.0,
    sessionId: sessionId,
  );
}

Widget _app(ProviderContainer container, Widget home) {
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
      home: home,
    ),
  );
}

Widget _confirmationStep(RecordingResult result) => ConfirmationStep(
  result: result,
  genreId: 'g1',
  subcategoryId: null,
  genreName: 'Genre',
  subcategoryName: null,
  onReRecord: () {},
  onDiscard: () {},
  onKeepForLater: () {},
  onSaved: () {},
);

Widget _confirmationApp(ProviderContainer container, RecordingResult result) {
  return _app(container, Scaffold(body: _confirmationStep(result)));
}

/// The tab-switch route: the form lives inside the real [AppShell], so tapping
/// a tab goes through the very code path the field team used.
Widget _shellApp(ProviderContainer container, RecordingResult result) {
  final router = GoRouter(
    initialLocation: '/record',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/record',
            builder: (_, _) => Scaffold(body: _confirmationStep(result)),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('home page'))),
          ),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

Finder get _titleField => find.byType(TextField).first;
Finder get _descriptionField => find.byType(TextField).last;

/// Lets the real futures run: drafts, Drift queries and file stats all hang off
/// work a bare `pump` does not advance.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _fillTheForm(WidgetTester tester) async {
  await tester.tap(find.byType(StorytellerPicker));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byType(StorytellerTile).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();

  await tester.enterText(_titleField, _typedTitle);
  await tester.pump();
  await tester.enterText(_descriptionField, _typedDescription);
  await _settle(tester);
}

/// The back button, as the platform delivers it.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.runAsync(() => tester.binding.handlePopRoute());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapDialogAction(WidgetTester tester, String label) async {
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(TextButton, label).last);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await _settle(tester);
}

List<InterruptedSession> _unsavedList(ProviderContainer container) =>
    container.read(interruptedSessionsProvider);

/// What the tab bar reaches when the person taps another tab.
Future<void> _tapHomeTab(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.bySemanticsLabel('Home tab'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await _settle(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Synchronous on purpose: `createTemp` never completes under the fake
    // clock a `testWidgets` body runs on.
    _docs = Directory.systemTemp.createTempSync('eng518_leave_');
    _db = AppDatabase.forTesting(NativeDatabase.memory());
    _sessions = RecordingSessionRepository(_db);

    // ConfirmationStep plus an open dialog overflows the 800x600 default
    // viewport; give it room so layout exceptions don't mask the real check.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      400 * 3.0,
      1200 * 3.0,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
    await _db.close();
    if (_docs.existsSync()) _docs.deleteSync(recursive: true);
  });

  testWidgets('1 — guardar para depois preserva o áudio', (tester) async {
    final container = _makeContainer();
    final result = await _seedFinishedRecording();
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);
    expect(find.text(_keepForLaterLabel), findsOneWidget);
    await _tapDialogAction(tester, _keepForLaterLabel);

    expect(File(result.filePath).existsSync(), isTrue);
    expect(
      _unsavedList(container).map((s) => s.sessionId),
      contains(_sessionId),
    );

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('2 — descartar continua apagando', (tester) async {
    final container = _makeContainer();
    final result = await _seedFinishedRecording();
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);
    await _tapDialogAction(tester, _discardLabel);

    expect(File(result.filePath).existsSync(), isFalse);
    expect(
      _unsavedList(container).map((s) => s.sessionId),
      isNot(contains(_sessionId)),
    );

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('3 — cancelar não faz nada', (tester) async {
    final container = _makeContainer();
    final result = await _seedFinishedRecording();
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);
    await _tapDialogAction(tester, _cancelLabel);

    expect(find.byType(ConfirmationStep), findsOneWidget);
    expect(File(result.filePath).existsSync(), isTrue);
    expect(_unsavedList(container), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('4 — trocar de aba oferece a mesma escolha', (tester) async {
    final container = _makeContainer();
    final result = await _seedFinishedRecording();
    await tester.pumpWidget(_shellApp(container, result));
    await _settle(tester);

    await _tapHomeTab(tester);
    expect(find.text(_keepForLaterLabel), findsOneWidget);
    await _tapDialogAction(tester, _keepForLaterLabel);

    expect(File(result.filePath).existsSync(), isTrue);
    expect(
      _unsavedList(container).map((s) => s.sessionId),
      contains(_sessionId),
    );

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('5 — a gravação guardada volta a ser editável', (tester) async {
    final container = _makeContainer();
    final result = await _seedFinishedRecording();
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);
    await _fillTheForm(tester);

    await _pressBack(tester);
    await _tapDialogAction(tester, _keepForLaterLabel);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    // Reopening it from the unsaved list is what the sheet's Save row does.
    final unsaved = _unsavedList(container);
    expect(unsaved.map((s) => s.sessionId), contains(_sessionId));
    final session = unsaved.firstWhere((s) => s.sessionId == _sessionId);
    final reopened = await tester.runAsync(
      () => container
          .read(interruptedSessionsNotifierProvider.notifier)
          .save(session.sessionId),
    );
    expect(reopened, isNotNull);

    final second = _makeContainer(
      pendingRecovery: PendingRecovery(
        result: reopened!,
        sessionId: session.sessionId,
        genreId: session.genreId,
        subcategoryId: session.subcategoryId,
      ),
    );
    await tester.pumpWidget(_app(second, const RecoveryConfirmScreen()));
    await _settle(tester);

    expect(File(reopened.filePath).existsSync(), isTrue);
    expect(find.text(_typedTitle), findsOneWidget);
    expect(find.text(_typedDescription), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('6 — sem sessão, a saída nova não é oferecida', (tester) async {
    final container = _makeContainer();
    final audioPath = '${_docs.path}/web_recording.webm';
    _createEmptyAudioFile(audioPath);
    // No sessionId: the browser never creates a session row, so there is
    // nowhere to park the audio.
    final result = RecordingResult(
      filePath: audioPath,
      durationSeconds: 5.0,
      format: 'webm',
    );
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);

    expect(find.text(_cancelLabel), findsOneWidget);
    expect(find.text(_discardLabel), findsWidgets);
    expect(find.text(_keepForLaterLabel), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
