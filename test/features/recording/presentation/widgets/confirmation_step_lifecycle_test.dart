// Integration regression test for ConfirmationStep's initState/dispose
// lifecycle. Two specific bugs we want to lock in:
//
//   - initState used to call `ref.read(pendingRecordingDecisionProvider
//     .notifier).state = widget.result` synchronously. When the widget is
//     mounted under Scaffold (a LayoutBuilder), initState runs inside a
//     build phase and Riverpod throws "Tried to modify a provider while
//     the widget tree was building".
//
//   - dispose used to read the provider via `ref` directly. Under
//     flutter_riverpod 2.x, `ref` is invalidated *before* State.dispose
//     runs, throwing "Cannot use ref after disposed". When that throws,
//     the marker stays set and AppShell's discard dialog pops up later
//     for a recording the user has already saved.
//
// The widget has heavy plugin dependencies (just_audio, ffmpeg, etc.) that
// are not available in flutter_test, so we keep this test narrow: we mount
// the real widget, drain the deferred initState mutation, then unmount it
// and confirm the marker is cleared without unhandled exceptions.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState();
}

class _FakeProjectStorytellersNotifier extends ProjectStorytellersNotifier {
  @override
  ProjectStorytellersState build() => const ProjectStorytellersState();

  @override
  Future<void> fetch(String projectId) async {}
}

const _result = RecordingResult(
  filePath: '/tmp/oral_collector_confirmation_test_nonexistent.m4a',
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
        ),
      ),
    ),
  );
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      projectStorytellersNotifierProvider.overrideWith(
        _FakeProjectStorytellersNotifier.new,
      ),
    ],
  );
}

void main() {
  setUp(() {
    // ConfirmationStep reads its saved draft from SharedPreferences on mount
    // (ENG-518); without a mock store the plugin channel throws.
    SharedPreferences.setMockInitialValues({});
    // ConfirmationStep renders a Column with multiple sections (waveform,
    // title field, storyteller picker, description, three buttons). At the
    // 800x600 default test viewport it overflows; we want enough vertical
    // space that the layout exception doesn't mask the real check below.
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
    'mounting under a Scaffold does not throw and sets pending decision',
    (tester) async {
      final container = _container();

      await tester.pumpWidget(_harness(container));
      // Drain the deferred initState mutation + the prefetch microtask.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(pendingRecordingDecisionProvider), equals(_result));

      // Tear down cleanly so subsequent tests start fresh.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      container.dispose();
    },
  );

  testWidgets(
    'unmounting clears pending decision without throwing during finalizeTree',
    (tester) async {
      final container = _container();

      await tester.pumpWidget(_harness(container));
      await tester.pump();
      expect(container.read(pendingRecordingDecisionProvider), equals(_result));

      // Replace the subtree so ConfirmationStep unmounts.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        ),
      );
      // Drain the deferred dispose mutation.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(pendingRecordingDecisionProvider), isNull);

      container.dispose();
    },
  );
}
