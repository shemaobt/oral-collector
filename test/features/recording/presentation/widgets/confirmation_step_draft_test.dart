// ENG-518 (fatia 1): o que a pessoa digita na tela de confirmação sobrevive à
// morte do processo. O campo de prova é o formulário, não o meio de guarda:
// cada teste digita, destrói a árvore de widgets inteira — que é o que a morte
// do processo faz do ponto de vista do formulário — e monta de novo do zero,
// então lê o que aparece nos campos. Nenhum assert sobre onde o rascunho foi
// guardado, com que chave, ou quando a escrita ocorreu.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

const _projectId = 'proj-1';
const _typedTitle = 'The River Spirits';
const _typedDescription =
    'A folk tale about the river spirits, told by an elder at dusk.';

const _recordingA = RecordingResult(
  filePath: '/tmp/oral_collector_eng518_a_nonexistent.m4a',
  durationSeconds: 5.0,
  format: 'm4a',
);

const _recordingB = RecordingResult(
  filePath: '/tmp/oral_collector_eng518_b_nonexistent.m4a',
  durationSeconds: 7.0,
  format: 'm4a',
);

final _storyteller = Storyteller(
  id: 'st1',
  projectId: _projectId,
  name: 'Test Storyteller',
  sex: StorytellerSex.male,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2024, 1, 1),
);

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

/// Containers here are deliberately never disposed. `ConfirmationStep.dispose`
/// clears its pending-decision marker from a deferred microtask, so tearing a
/// container down while that microtask is still queued throws "used after
/// dispose" — and a dead process disposes nothing anyway. Every provider in
/// these overrides is an in-memory fake, so leaving them is free.
ProviderContainer _makeContainer({PendingRecovery? pendingRecovery}) {
  final container = ProviderContainer(
    overrides: [
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      projectStorytellersNotifierProvider.overrideWith(
        _FakeProjectStorytellersNotifier.new,
      ),
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      localRecordingRepositoryProvider.overrideWithValue(
        _RecordingRepositorySpy(),
      ),
      recordingApiRepositoryProvider.overrideWithValue(_EmptyApiRepo()),
    ],
  );
  if (pendingRecovery != null) {
    container.read(pendingRecoveryProvider.notifier).state = pendingRecovery;
  }
  return container;
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

Widget _confirmationApp(ProviderContainer container, RecordingResult result) {
  return _app(
    container,
    Scaffold(
      body: ConfirmationStep(
        result: result,
        genreId: 'g1',
        subcategoryId: null,
        genreName: 'Genre',
        subcategoryName: null,
        onReRecord: () {},
        onDiscard: () {},
        onKeepForLater: () {},
        onSaved: () {},
      ),
    ),
  );
}

Finder get _titleField => find.byType(TextField).first;
Finder get _descriptionField => find.byType(TextField).last;

/// Lets the asynchronous draft read/write actually run: both hang off real
/// futures that a bare `pump` does not advance.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump();
}

/// What the death of the process does from the form's point of view: the whole
/// widget tree is gone and the next mount starts from a container that never
/// saw it. The old container is left to the teardown rather than disposed here
/// — process death runs no disposers, and disposing mid-test would race the
/// deferred cleanup `ConfirmationStep.dispose` schedules.
Future<void> _killTheTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await _settle(tester);
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

Future<void> _tapSave(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byType(ElevatedButton));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump();
}

Future<void> _tapDiscardAndConfirm(WidgetTester tester) async {
  await tester.tap(find.byType(TextButton).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.widgetWithText(TextButton, 'Discard').last);
  await _settle(tester);
}

void _expectFilledIn(WidgetTester tester) {
  expect(find.text(_typedTitle), findsOneWidget);
  expect(find.text(_typedDescription), findsOneWidget);
  expect(find.text(_storyteller.name), findsOneWidget);
  // Reopening puts the caret after the restored text, not before it: typing
  // straight away must continue the sentence rather than deface it.
  expect(
    tester
        .widget<TextField>(_descriptionField)
        .controller!
        .selection
        .baseOffset,
    _typedDescription.length,
  );
}

void _expectBlank(WidgetTester tester) {
  expect(find.text(_typedTitle), findsNothing);
  expect(find.text(_typedDescription), findsNothing);
  expect(find.text(_storyteller.name), findsNothing);
  expect(tester.widget<TextField>(_descriptionField).controller!.text, isEmpty);
}

void main() {
  setUp(() {
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

  testWidgets('1 — o que foi digitado volta quando a mesma gravação reabre', (
    tester,
  ) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingA));
    await _settle(tester);

    _expectFilledIn(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('2 — a gravação recuperada de crash também volta preenchida', (
    tester,
  ) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _killTheTree(tester);

    final second = _makeContainer(
      pendingRecovery: const PendingRecovery(
        result: _recordingA,
        sessionId: 'sess-1',
        genreId: 'g1',
        subcategoryId: null,
      ),
    );
    await tester.pumpWidget(_app(second, const RecoveryConfirmScreen()));
    await _settle(tester);

    _expectFilledIn(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('3 — o rascunho de uma gravação não vaza para outra', (
    tester,
  ) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingB));
    await _settle(tester);

    _expectBlank(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('4 — salvar não deixa rascunho para trás', (tester) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _tapSave(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingB));
    await _settle(tester);

    _expectBlank(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  // Os testes 4 e 5 abrem uma gravação *nova*, cuja chave já é outra por
  // construção: sozinhos, passam mesmo se a limpeza nunca acontecer. Estes dois
  // reabrem a mesma gravação, que é onde um rascunho sobrevivente apareceria.
  testWidgets('4b — depois de salvar, a mesma gravação reabre vazia', (
    tester,
  ) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _tapSave(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingA));
    await _settle(tester);

    _expectBlank(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('5b — depois de descartar, a mesma gravação reabre vazia', (
    tester,
  ) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _tapDiscardAndConfirm(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingA));
    await _settle(tester);

    _expectBlank(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('5 — descartar não deixa rascunho para trás', (tester) async {
    final first = _makeContainer();
    await tester.pumpWidget(_confirmationApp(first, _recordingA));
    await _settle(tester);
    await _fillTheForm(tester);
    await _tapDiscardAndConfirm(tester);
    await _killTheTree(tester);

    final second = _makeContainer();
    await tester.pumpWidget(_confirmationApp(second, _recordingB));
    await _settle(tester);

    _expectBlank(tester);

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
