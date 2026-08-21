/// ENG-519 (fatia 3): sair da tela de confirmação no navegador oferece guardar
/// para depois.
///
/// A terceira saída aparece quando quem abre o diálogo diz que há onde guardar,
/// e o critério é ter identificador de sessão. A fatia 1 fez a captura no
/// navegador passar a ter um — mas ninguém nunca exercitou essa saída lá, e o
/// comentário da produção ainda dizia que o navegador "não cria linha de sessão
/// nenhuma".
///
/// Cada caso dirige a captura de produção do navegador, monta a tela de
/// confirmação com o resultado que ela devolveu, e sai pela interface. O que se
/// olha é o que a pessoa vê: o áudio continua lá? a gravação está na lista?
///
/// O áudio capturado é deliberadamente vazio: a tela pula o carregamento do
/// tocador para um arquivo de zero bytes, e um tocador carregado busca o canal
/// do just_audio que nenhum teste de widget tem. O que está sob teste é a
/// decisão de guardar ou apagar, e os bytes de dentro não opinam nela.
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_notifier.dart';
import 'package:oral_collector/features/invite/presentation/notifiers/invite_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keepForLaterLabel = 'Keep for later';
const _discardLabel = 'Discard';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

class _FakeRecordConfig extends Fake implements RecordConfig {}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(
    projects: [Project(id: 'proj-1', name: 'Project', languageId: 'l1')],
    activeProject: Project(id: 'proj-1', name: 'Project', languageId: 'l1'),
  );
}

class _FakeProjectStorytellersNotifier extends ProjectStorytellersNotifier {
  @override
  ProjectStorytellersState build() => const ProjectStorytellersState();
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState();

  @override
  Future<void> processQueue() async {}
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
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

class _EmptyApiRepo implements RecordingApiRepository {
  @override
  Future<ServerRecording> getRecording(String id) => throw UnimplementedError();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

late Directory _docs;
late AppDatabase _db;
late _MockAudioRecorder _recorder;
late StreamController<RecordState> _recorderState;

/// Nunca descartado, pelo motivo que a suíte do ENG-518 documenta:
/// `ConfirmationStep.dispose` limpa o marcador de decisão pendente de um
/// microtask adiado, e derrubar o container com ele na fila lança.
ProviderContainer _makeWebContainer() => ProviderContainer(
  overrides: [
    appDatabaseProvider.overrideWithValue(_db),
    isWebPlatformProvider.overrideWithValue(true),
    webAudioRecorderFactoryProvider.overrideWithValue(() => _recorder),
    inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
    recoveryCoordinatorProvider.overrideWith(
      (ref) => RecoveryCoordinator(
        ref,
        disk: RecoveryDisk(documentsPath: () async => _docs.path),
      ),
    ),
    projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
    projectStorytellersNotifierProvider.overrideWith(
      _FakeProjectStorytellersNotifier.new,
    ),
    syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
    genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
    recordingApiRepositoryProvider.overrideWithValue(_EmptyApiRepo()),
    inviteNotifierProvider.overrideWith(_FakeInviteNotifier.new),
    roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
  ],
);

/// A captura de produção do navegador, do início ao fim. Devolve o resultado
/// com que a tela de confirmação seria aberta de verdade.
Future<RecordingResult> _captureInBrowser(
  WidgetTester tester,
  ProviderContainer container,
) async {
  late RecordingResult result;
  await tester.runAsync(() async {
    final notifier = container.read(recordingSessionNotifierProvider.notifier);
    expect(
      await notifier.startRecording(
        'gen_narrative',
        'sub_genealogy',
        projectId: 'proj-1',
      ),
      isTrue,
    );
    final stopped = await http.runWithClient(
      notifier.stopRecording,
      () => MockClient((_) async => http.Response.bytes(Uint8List(0), 200)),
    );
    expect(stopped, isNotNull);
    result = stopped!;
  });
  addTearDown(() {
    final leftover = File(result.filePath);
    if (leftover.existsSync()) leftover.deleteSync();
  });
  return result;
}

Widget _confirmationApp(ProviderContainer container, RecordingResult result) =>
    UncontrolledProviderScope(
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
            result: result,
            genreId: 'gen_narrative',
            subcategoryId: 'sub_genealogy',
            genreName: 'Narrative',
            subcategoryName: 'Genealogy',
            onReRecord: () {},
            onDiscard: () {},
            onKeepForLater: () {},
            onSaved: () {},
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

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

Future<List<String>> _unsavedList(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.runAsync(
    () => container.read(recoveryCoordinatorProvider).refresh(),
  );
  return container
      .read(interruptedSessionsProvider)
      .map((s) => s.sessionId)
      .toList();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Síncrono de propósito: `createTemp` não completa sob o relógio falso.
    _docs = Directory.systemTemp.createTempSync('eng519c_leave_');
    _db = AppDatabase.forTesting(NativeDatabase.memory());

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => _docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    _recorder = _MockAudioRecorder();
    _recorderState = StreamController<RecordState>.broadcast();
    when(() => _recorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => _recorder.start(any(), path: any(named: 'path')),
    ).thenAnswer((_) async {});
    when(
      () => _recorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());
    when(
      () => _recorder.onStateChanged(),
    ).thenAnswer((_) => _recorderState.stream);
    when(
      () => _recorder.stop(),
    ).thenAnswer((_) async => 'https://recorder.invalid/captured-blob');
    when(() => _recorder.dispose()).thenAnswer((_) async {});

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
    await _recorderState.close();
    await _db.close();
    if (_docs.existsSync()) _docs.deleteSync(recursive: true);
  });

  testWidgets('no navegador, sair oferece guardar para depois', (tester) async {
    final container = _makeWebContainer();
    final result = await _captureInBrowser(tester, container);
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);

    // Dentro do diálogo: a própria tela de confirmação tem um botão de
    // descartar, e procurar no widget inteiro acharia os dois.
    Finder inDialog(String label) => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, label),
    );

    expect(
      inDialog(_keepForLaterLabel),
      findsOneWidget,
      reason: 'a fatia 1 deu ao navegador a linha onde guardar',
    );
    expect(inDialog(_discardLabel), findsOneWidget);
    expect(inDialog('Cancel'), findsOneWidget, reason: 'as três saídas');

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('guardar para depois no navegador preserva o áudio', (
    tester,
  ) async {
    final container = _makeWebContainer();
    final result = await _captureInBrowser(tester, container);
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);
    await _tapDialogAction(tester, _keepForLaterLabel);

    expect(
      await tester.runAsync(() => file_ops.fileExists(result.filePath)),
      isTrue,
      reason: 'guardar não pode custar o áudio',
    );
    expect(
      await _unsavedList(tester, container),
      contains(result.sessionId),
      reason: 'guardar é para poder voltar: tem de estar na lista',
    );

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });

  testWidgets('descartar no navegador continua apagando', (tester) async {
    final container = _makeWebContainer();
    final result = await _captureInBrowser(tester, container);
    await tester.pumpWidget(_confirmationApp(container, result));
    await _settle(tester);

    await _pressBack(tester);
    await _tapDialogAction(tester, _discardLabel);

    expect(
      await tester.runAsync(() => file_ops.fileExists(result.filePath)),
      isFalse,
      reason: 'a pessoa pediu para apagar',
    );
    expect(
      await _unsavedList(tester, container),
      isNot(contains(result.sessionId)),
    );

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
