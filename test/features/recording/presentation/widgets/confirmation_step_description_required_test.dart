// ENG-354: a recording is only useful to a linguist if it says what it is, so
// the confirmation step refuses to save a description shorter than
// [minDescriptionGraphemes]. Both save paths route through `_save`, so the
// guard sits there and covers the native repository write and the web direct
// upload alike.
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
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/recording_description.dart';

const _projectId = 'proj-1';
const _tooShort = 'Too short';
const _longEnough = 'A folk tale about the river spirits, told by an elder.';

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
  _FakeProjectStorytellersNotifier(this._initial);

  final ProjectStorytellersState _initial;

  @override
  ProjectStorytellersState build() => _initial;

  @override
  Future<void> fetch(String projectId) async {}
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: false);

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
  filePath: '/tmp/oral_collector_description_required_test_nonexistent.m4a',
  durationSeconds: 5.0,
  format: 'm4a',
);

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
          onSaved: () {},
        ),
      ),
    ),
  );
}

Finder get _descriptionField => find.byType(TextField).last;

Future<void> _pickStoryteller(WidgetTester tester) async {
  await tester.tap(find.byType(StorytellerPicker));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // open animation
  await tester.tap(find.byType(StorytellerTile).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // close animation
  await tester.pump();
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester) async {
  // The save path awaits real file I/O and the title lookup, which only advance
  // inside runAsync; run the tap there, then pump to render the resulting UI.
  await tester.runAsync(() async {
    await tester.tap(find.byType(ElevatedButton));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  final l10nEn = AppLocalizationsEn();
  final tooShortMessage = l10nEn.recording_descriptionTooShort(
    minDescriptionGraphemes,
  );

  late _RecordingRepositorySpy repo;
  late ProviderContainer container;

  setUp(() {
    // ConfirmationStep plus an open bottom sheet overflows the 800x600 default
    // viewport; give it room so layout exceptions don't mask the real check.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      400 * 3.0,
      1200 * 3.0,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;

    repo = _RecordingRepositorySpy();
    container = ProviderContainer(
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
        recordingApiRepositoryProvider.overrideWithValue(_EmptyApiRepo()),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('a too-short description blocks the save and is explained', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStoryteller(tester);

    await tester.enterText(_descriptionField, _tooShort);
    await tester.pump();
    await _tapSave(tester);

    expect(find.text(tooShortMessage), findsOneWidget);
    expect(repo.saved, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('an empty description blocks the save', (tester) async {
    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStoryteller(tester);
    await _tapSave(tester);

    expect(find.text(tooShortMessage), findsOneWidget);
    expect(repo.saved, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('lengthening the description clears the error and saves', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(container));
    await tester.pump();
    await _pickStoryteller(tester);

    await tester.enterText(_descriptionField, _tooShort);
    await tester.pump();
    await _tapSave(tester);
    expect(find.text(tooShortMessage), findsOneWidget);

    await tester.enterText(_descriptionField, _longEnough);
    await tester.pump();

    expect(find.text(tooShortMessage), findsNothing);

    await _tapSave(tester);

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.description, _longEnough);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
