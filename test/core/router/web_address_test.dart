import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';

import '../../support/router_app.dart';

class _WebLocal extends FakeLocal {
  @override
  Future<List<LocalRecording>> getPendingWebUploads() async => const [];
}

class _NoProject extends FakeProjectNotifier {
  @override
  ProjectState build() => const ProjectState(projects: <Project>[]);
}

class _Api extends FakeApi {
  bool deleted = false;

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
  }) async => deleted ? [] : [serverRecording];
}

String addressOf(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

Future<ProviderContainer> _pumpWeb(
  WidgetTester tester, {
  required String at,
  List<Override> overrides = const [],
  bool settled = true,
}) => pumpApp(
  tester,
  at: at,
  settled: settled,
  overrides: [
    isWebPlatformProvider.overrideWithValue(true),
    localRecordingRepositoryProvider.overrideWithValue(_WebLocal()),
    ...overrides,
  ],
);

void main() {
  testWidgets('opening a recording from the list sets its address', (
    tester,
  ) async {
    final app = await _pumpWeb(tester, at: '/recordings');

    await tester.tap(find.byType(RecordingCard));
    await settle(tester);

    expect(addressOf(app), '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('the app built at a recording shows it, without the list', (
    tester,
  ) async {
    await _pumpWeb(tester, at: '/recording/r1');

    expect(find.byType(RecordingDetailScreen), findsOneWidget);
    expect(find.byType(RecordingsListScreen), findsNothing);
  });

  testWidgets('back from a recording shows the list without what was deleted', (
    tester,
  ) async {
    final api = _Api();
    final app = await _pumpWeb(
      tester,
      at: '/recordings',
      overrides: [recordingApiRepositoryProvider.overrideWithValue(api)],
    );
    await tester.tap(find.byType(RecordingCard));
    await settle(tester);

    api.deleted = true;
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(addressOf(app), '/recordings');
    expect(find.byType(RecordingCard), findsNothing);
  });

  testWidgets('back from the editor returns to its recording', (tester) async {
    final app = await _pumpWeb(tester, at: '/recording/r1/trim');
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(addressOf(app), '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('import without an active project goes home', (tester) async {
    final app = await _pumpWeb(
      tester,
      at: '/import-file',
      settled: false,
      overrides: [projectNotifierProvider.overrideWith(_NoProject.new)],
    );

    expect(addressOf(app), '/home');
  });
}
