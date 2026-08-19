// ENG-179: the save/confirmation screen must survive a large system font
// (MediaQuery textScaler) on a realistic phone viewport without overflowing.
// The lower section (title, storyteller picker, description, action buttons)
// must scroll instead of overflowing the column.
//
// ConfirmationStep defers a provider mutation to a microtask in dispose(), so
// the harness keeps an external container alive across unmount (mirroring
// confirmation_step_lifecycle_test) instead of tearing the ProviderScope down.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/text_scale.dart';

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
  filePath: '/tmp/oral_collector_confirmation_text_scale_nonexistent.m4a',
  durationSeconds: 5.0,
  format: 'm4a',
);

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

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  double scale,
) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
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
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: const ConfirmationStep(
                result: _result,
                genreId: 'g1',
                subcategoryId: null,
                genreName: 'Genre',
                subcategoryName: null,
                onReRecord: _noop,
                onDiscard: _noop,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _noop() {}

Future<void> _unmount(WidgetTester tester, ProviderContainer container) async {
  // Keep the same container alive so ConfirmationStep's deferred dispose
  // microtask can clear its marker without touching a disposed controller.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    ),
  );
  await tester.pump();
  container.dispose();
}

void main() {
  setUp(() {
    // ConfirmationStep reads its saved draft from SharedPreferences on mount
    // (ENG-518); without a mock store the plugin channel throws.
    SharedPreferences.setMockInitialValues({});
  });

  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('confirmation has no overflow at ${scale}x', (tester) async {
      final container = _container();
      await _pump(tester, container, scale);
      expectNoOverflow(tester);
      await _unmount(tester, container);
    });
  }
}
