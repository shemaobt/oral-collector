import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../support/text_scale.dart';

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

ServerRecording _recording(String title) => ServerRecording(
  id: 'r1',
  projectId: 'p1',
  genreId: 'g1',
  title: title,
  durationSeconds: 42,
  fileSizeBytes: 2048,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
);

class _FakeApi implements RecordingApiRepository {
  _FakeApi(this.title);

  String title;

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
  }) async => [_recording(this.title)];

  @override
  Future<ServerRecording> getRecording(String id) =>
      throw StateError('the detail screen resolves to not-found in this test');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeLocal implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  Future<List<LocalRecording>> getPendingWebUploads() async => const [];

  @override
  Future<LocalRecording?> getRecordingById(String id) async => null;

  @override
  Future<LocalRecording?> getRecordingByServerId(String serverId) async => null;

  @override
  Future<LocalRecordingEntity?> getRecordingEntityById(String id) async => null;

  @override
  Future<LocalRecordingEntity?> getRecordingEntityByServerId(
    String serverId,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u1', email: 'a@b.c', isPlatformAdmin: false),
  );
}

class _FakeProject extends ProjectNotifier {
  _FakeProject(this.active);

  final Project? active;

  @override
  ProjectState build() =>
      ProjectState(projects: const [_project], activeProject: active);
}

class _FakeGenre extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class _OnlineSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

class _FakeRole extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  @override
  Future<void> fetchRoleForProject(String projectId) async {}
}

class _FakeMember extends MemberNotifier {
  @override
  MemberState build() => const MemberState();

  @override
  Future<void> fetchMembers(String projectId) async {}
}

Future<_App> _pumpWebApp(
  WidgetTester tester, {
  required String at,
  Project? activeProject = _project,
  bool settle = true,
}) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final api = _FakeApi('The hunter and the river');
  final container = ProviderContainer(
    overrides: [
      isWebPlatformProvider.overrideWithValue(true),
      authNotifierProvider.overrideWith(_FakeAuth.new),
      syncNotifierProvider.overrideWith(_OnlineSync.new),
      genreNotifierProvider.overrideWith(_FakeGenre.new),
      projectNotifierProvider.overrideWith(() => _FakeProject(activeProject)),
      roleNotifierProvider.overrideWith(_FakeRole.new),
      memberNotifierProvider.overrideWith(_FakeMember.new),
      recordingApiRepositoryProvider.overrideWithValue(api),
      localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
      localRecordingStreamProvider(
        'r1',
      ).overrideWith((ref) => const Stream<LocalRecordingEntity?>.empty()),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(routerProvider)..go(at);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await (settle ? tester.pumpAndSettle() : tester.pump());
  return _App(router, api);
}

class _App {
  _App(this.router, this.api) {
    router.routerDelegate.addListener(() => visited.add(address));
  }

  final visited = <String>[];

  final GoRouter router;
  final _FakeApi api;

  String get address =>
      router.routerDelegate.currentConfiguration.uri.toString();
}

void main() {
  testWidgets('opening a recording from the list sets its address', (
    tester,
  ) async {
    final app = await _pumpWebApp(tester, at: '/recordings');

    await tester.tap(find.byType(RecordingCard));
    await tester.pumpAndSettle();

    expect(app.address, '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('the app built at a recording shows it, without the list', (
    tester,
  ) async {
    await _pumpWebApp(tester, at: '/recording/r1');

    expect(find.byType(RecordingDetailScreen), findsOneWidget);
    expect(find.byType(RecordingsListScreen), findsNothing);
  });

  testWidgets('back from a recording shows the list with what changed', (
    tester,
  ) async {
    final app = await _pumpWebApp(tester, at: '/recordings');
    await tester.tap(find.byType(RecordingCard));
    await tester.pumpAndSettle();

    app.api.title = 'The hunter, renamed';
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(app.address, '/recordings');
    expect(find.text('The hunter, renamed'), findsOneWidget);
  });

  testWidgets('back from the editor returns to its recording', (tester) async {
    final app = await _pumpWebApp(tester, at: '/recording/r1/trim');
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(app.address, '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('import without an active project goes home', (tester) async {
    final app = await _pumpWebApp(
      tester,
      at: '/import-file',
      activeProject: null,
      settle: false,
    );

    expect(app.address, '/home');
  });

  testWidgets('opening import from the list sets its address', (tester) async {
    final app = await _pumpWebApp(tester, at: '/recordings');

    await tester.tap(find.bySemanticsLabel('Import audio file'));
    await tester.pump();

    expect(app.visited, contains('/import-file'));
  });
}
