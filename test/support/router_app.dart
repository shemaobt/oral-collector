import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import 'text_scale.dart';

const recordingId = 'r1';
const project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

final serverRecording = ServerRecording(
  id: recordingId,
  projectId: 'p1',
  genreId: 'g1',
  title: 'The hunter and the river',
  durationSeconds: 42,
  fileSizeBytes: 2048,
  format: 'm4a',
  uploadStatus: 'uploaded',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
);

/// Lists the one recording the list screen shows, and refuses to resolve it
/// afterwards.
///
/// The refusal is what keeps the detail screen in its not-found state, the one
/// state that renders without the hero player — the player takes near-unbounded
/// constraints under the test font and overflows (see
/// this file asserts, and that is the same in either state.
class FakeApi implements RecordingApiRepository {
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
  }) async => [serverRecording];

  @override
  Future<ServerRecording> getRecording(String id) =>
      throw StateError('the detail screen resolves to not-found in this test');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class FakeLocal implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

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

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u1', email: 'a@b.c', isPlatformAdmin: false),
  );
}

class FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() =>
      const ProjectState(projects: [project], activeProject: project);
}

class FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class OnlineSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

class FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  @override
  Future<void> fetchRoleForProject(String projectId) async {}
}

class FakeMemberNotifier extends MemberNotifier {
  @override
  MemberState build() => const MemberState();

  @override
  Future<void> fetchMembers(String projectId) async {}
}

/// Boots the app's own router at [at] and pumps until it is quiet.
///
/// The router starts at `/home`, so [at] is applied with `go` before the first
/// pump: `go` replaces the stack, which leaves exactly one entry on it — the
/// state a freshly launched app is in — and spares this file the home screen's
/// unrelated dependency thicket.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required String at,
}) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(FakeAuthNotifier.new),
      syncNotifierProvider.overrideWith(OnlineSync.new),
      genreNotifierProvider.overrideWith(FakeGenreNotifier.new),
      projectNotifierProvider.overrideWith(FakeProjectNotifier.new),
      roleNotifierProvider.overrideWith(FakeRoleNotifier.new),
      memberNotifierProvider.overrideWith(FakeMemberNotifier.new),
      recordingApiRepositoryProvider.overrideWithValue(FakeApi()),
      localRecordingRepositoryProvider.overrideWithValue(FakeLocal()),
      // The real Drift watch stream leaves a pending Timer that flutter_test
      // flags on teardown.
      localRecordingStreamProvider(
        recordingId,
      ).overrideWith((ref) => const Stream<LocalRecordingEntity?>.empty()),
    ],
  );
  addTearDown(container.dispose);

  container.read(routerProvider).go(at);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: container.read(routerProvider),
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
  await settle(tester);
  return container;
}

/// Settles by pumping until no frame is scheduled, never by a fixed number of
/// pumps.
///
/// A counted `pump(50ms)` loop is not equivalent here and quietly lies: a route
/// removed by a system back stays mounted through ten of them, so the test goes
/// red on a defect that is not there.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();
