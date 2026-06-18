// Regression test for ENG-80: the native save path in ConfirmationStep used to
// call repo.insertRecording without a try/catch. On failure the Save button
// stayed disabled (spinner forever) and the exception went unhandled. The web
// path already recovered; this locks the native path to the same contract:
// surface the error and re-enable the button.
//
// Driving the real StorytellerPicker bottom sheet is necessary because the
// Save handler bails out unless a storyteller is selected, and that selection
// is private widget state only reachable through the picker UI.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
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

class _ThrowingRecordingRepository implements LocalRecordingRepository {
  @override
  Future<void> saveRecording({
    required String id,
    required String projectId,
    required String genreId,
    required String storytellerId,
    required String title,
    required double durationSeconds,
    required int fileSizeBytes,
    required String format,
    required String localFilePath,
    required DateTime recordedAt,
    String? subcategoryId,
    String? registerId,
    String? description,
    String? userId,
    String? serverId,
    String? uploadStatus,
  }) async {
    throw Exception('save failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState();
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
  _FakeSyncNotifier(this._initial);

  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

final _storyteller = Storyteller(
  id: 'st1',
  projectId: '',
  name: 'Test Storyteller',
  sex: StorytellerSex.male,
  externalAcceptanceConfirmed: true,
  createdAt: DateTime(2024, 1, 1),
);

const _result = RecordingResult(
  filePath: '/tmp/oral_collector_save_error_test_nonexistent.m4a',
  durationSeconds: 5.0,
  format: 'm4a',
);

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      projectStorytellersNotifierProvider.overrideWith(
        () => _FakeProjectStorytellersNotifier(
          ProjectStorytellersState(projectId: '', storytellers: [_storyteller]),
        ),
      ),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(const SyncState()),
      ),
      localRecordingRepositoryProvider.overrideWithValue(
        _ThrowingRecordingRepository(),
      ),
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
        ),
      ),
    ),
  );
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

  testWidgets(
    'native save surfaces an error and re-enables the button when the insert fails',
    (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_harness(container));
      await tester.pump(); // drain the deferred initState microtasks

      // Select a storyteller (required) through the picker's bottom sheet.
      await tester.tap(find.byType(StorytellerPicker));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // open animation
      await tester.tap(find.byType(StorytellerTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // close animation
      await tester.pump(); // resume _open() -> onChanged -> setState
      await tester.pump(); // rebuild with Save enabled

      // Save -> native path -> insertRecording throws. _save() awaits real file
      // I/O (file_ops.fileLength), which only advances inside runAsync; run the
      // whole tap there so _save reaches the insert, then pump to render the UI.
      await tester.runAsync(() async {
        await tester.tap(find.byType(ElevatedButton));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(); // flush setState/showSnackBar scheduled in _save
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Upload failed'), findsOneWidget);
      // Routed through the unified showErrorSnackBar -> styled alert icon.
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);

      final saveButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(saveButton.onPressed, isNotNull);

      // Unmount so the widget disposes its AudioPlayer before the test ends.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
