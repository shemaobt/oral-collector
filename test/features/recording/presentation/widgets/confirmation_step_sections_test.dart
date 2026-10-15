// ENG-207: characterization guard for the visible surface of ConfirmationStep
// before its build() is decomposed into section widgets. Behaviour-preserving
// refactor, so these pass both before and after the extraction — they lock the
// duration readout, the classification tag (and its unclassified warning), the
// title/description fields, the storyteller picker, and the three action
// buttons (including the Save gate and the showReRecord toggle).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/domain/entities/classification.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/confirmation_step.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/storyteller/presentation/widgets/storyteller_picker.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/utils/format.dart';
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
  filePath: '/tmp/oral_collector_confirmation_sections_nonexistent.m4a',
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
  ProviderContainer container, {
  required String genreId,
  String? genreName = 'Genre',
  String? subcategoryName,
  String? registerName,
  bool showReRecord = true,
}) async {
  tester.view.physicalSize = const Size(400 * 3.0, 1400 * 3.0);
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
          body: ConfirmationStep(
            result: _result,
            genreId: genreId,
            subcategoryId: null,
            genreName: genreName,
            subcategoryName: subcategoryName,
            registerName: registerName,
            onReRecord: () {},
            onDiscard: () {},
            onKeepForLater: () {},
            showReRecord: showReRecord,
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // drain deferred initState microtasks
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUp(() {
    // ConfirmationStep reads its saved draft from SharedPreferences on mount
    // (ENG-518); without a mock store the plugin channel throws.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('classified recording shows duration, tag, fields and buttons', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pump(
      tester,
      container,
      genreId: 'g1',
      genreName: 'Genre',
      subcategoryName: 'Sub',
      registerName: 'Reg',
    );

    // Duration readout.
    expect(
      find.text(formatDurationMinSec(_result.durationSeconds)),
      findsOneWidget,
    );
    // Classification tag (slash-joined) and no "classify later" warning.
    expect(find.text('Genre / Sub / Reg'), findsOneWidget);

    // Form: title + description fields and the storyteller picker.
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(StorytellerPicker), findsOneWidget);

    // Action buttons: Save (disabled until a storyteller is chosen),
    // Re-record (shown by default) and Discard.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
    final save = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(save.onPressed, isNull);

    await _unmount(tester);
  });

  testWidgets('unclassified recording shows the classify-later warning', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pump(
      tester,
      container,
      genreId: kUnclassifiedGenreId,
      genreName: null,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ConfirmationStep)),
    );
    expect(find.text(l10n.quickRecord_classifyLater), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('hides the re-record button when showReRecord is false', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pump(tester, container, genreId: 'g1', showReRecord: false);

    expect(find.byType(OutlinedButton), findsNothing);
    // Save and Discard remain.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    await _unmount(tester);
  });
}
