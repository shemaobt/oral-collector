/// The pendency breakdown has to be a way in, not just a number (ENG-381).
///
/// Driven through the real router and the real screens on purpose. Every part
/// of this can be green on its own — a tappable row, a route that reads a query
/// parameter, a notifier that filters — while the chain between them is broken,
/// and that is exactly how ENG-374 shipped a counter nobody could act on.
library;

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
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_settings_header.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../support/text_scale.dart';

final _l10n = AppLocalizationsEn();

const _thisProject = Project(
  id: 'p1',
  name: 'Kwanga stories',
  languageId: 'l1',
);
const _otherProject = Project(id: 'p2', name: 'Elsewhere', languageId: 'l1');

const _stats = ProjectStats(
  totalRecordings: 12,
  recordingsWithReviewFlags: 3,
  reviewFlagCounts: {'missing_classification': 3, 'missing_storyteller': 2},
);

/// Records what the fake notifiers were asked to do. Kept out of the notifiers
/// themselves: a public field on a Notifier trips `avoid_public_notifier_properties`.
final _setActiveCalls = <String>[];

class _FakeProjectRepository implements ProjectRepository {
  @override
  Future<Project> getProject(String id) async => _thisProject;

  @override
  Future<ProjectStats> getProjectStats(String projectId) async => _stats;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier(this._initial);

  final ProjectState _initial;

  @override
  ProjectState build() => _initial;

  @override
  Future<void> setActiveProject(Project project) async {
    _setActiveCalls.add(project.id);
    state = state.copyWith(activeProject: project);
  }
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  @override
  bool canManageProject(String projectId) => true;

  @override
  Future<void> fetchRoleForProject(String projectId) async {}
}

class _FakeMemberNotifier extends MemberNotifier {
  @override
  MemberState build() => const MemberState();

  @override
  Future<void> fetchMembers(String projectId) async {}
}

class _FakeSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

class _FakeGenreNotifier extends GenreNotifier {
  @override
  GenreState build() => const GenreState();

  @override
  Future<void> fetchGenres() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u1', email: 'a@b.c', isPlatformAdmin: false),
  );
}

class _FakeRecordingApi implements RecordingApiRepository {
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

class _FakeLocalRepository implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

/// Boots the app's own router at the settings screen for [activeProject].
///
/// [GoRouter.go] before the first pump so the home screen never builds: this
/// test is about the route between two screens, not about the third.
Future<ProviderContainer> pumpSettings(
  WidgetTester tester, {
  required Project? activeProject,
}) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
      genreNotifierProvider.overrideWith(_FakeGenreNotifier.new),
      projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
      projectNotifierProvider.overrideWith(
        () => _FakeProjectNotifier(
          ProjectState(
            projects: const [_thisProject, _otherProject],
            activeProject: activeProject,
          ),
        ),
      ),
      roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
      memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
      recordingApiRepositoryProvider.overrideWithValue(_FakeRecordingApi()),
      localRecordingRepositoryProvider.overrideWithValue(
        _FakeLocalRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  router.go('/project/p1/settings');

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
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return container;
}

Finder _breakdownLine(String label, int count) => find.text('$label: $count');

void main() {
  setUp(_setActiveCalls.clear);

  testWidgets('the breakdown line opens the list narrowed to that pendency', (
    tester,
  ) async {
    final container = await pumpSettings(tester, activeProject: _thisProject);

    await tester.tap(_breakdownLine(_l10n.recording_pendencyClassification, 3));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      PendencyKind.classification,
    );
    expect(find.byType(RecordingsListScreen), findsOneWidget);
  });

  testWidgets('each line carries its own pendency, not the first one', (
    tester,
  ) async {
    final container = await pumpSettings(tester, activeProject: _thisProject);

    await tester.tap(_breakdownLine(_l10n.recording_pendencyStoryteller, 2));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      PendencyKind.storyteller,
    );
  });

  testWidgets('opening the list for a project that is not the active one '
      'switches to it first', (tester) async {
    // Settings can be opened for any project in the list, but the recordings
    // list only ever reads the active one. Pushing without switching would show
    // a different project's recordings under this project's number.
    final container = await pumpSettings(tester, activeProject: _otherProject);

    await tester.tap(_breakdownLine(_l10n.recording_pendencyClassification, 3));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(_setActiveCalls, ['p1']);
    expect(container.read(projectNotifierProvider).activeProject?.id, 'p1');
    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      PendencyKind.classification,
    );
  });

  testWidgets('the list stays where it was when settings is already on the '
      'active project', (tester) async {
    await pumpSettings(tester, activeProject: _thisProject);

    await tester.tap(_breakdownLine(_l10n.recording_pendencyClassification, 3));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(_setActiveCalls, isEmpty);
  });

  testWidgets('the breakdown line announces itself as a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpSettings(tester, activeProject: _thisProject);

    expect(
      find.bySemanticsLabel(
        _l10n.projectStats_showPendency(
          _l10n.recording_pendencyClassification,
          3,
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the breakdown line survives the largest supported text', (
    tester,
  ) async {
    await pumpAtTextScale(
      tester,
      scale: 2.0,
      child: SingleChildScrollView(
        child: ProjectSettingsStatsSection(
          project: _thisProject,
          memberCount: 4,
          stats: _stats,
          onPendencyTap: (_) {},
        ),
      ),
    );

    expectNoOverflow(tester);
    expect(
      _breakdownLine(_l10n.recording_pendencyClassification, 3),
      findsOneWidget,
    );
  });

  testWidgets('a tap lands anywhere on a target big enough to hit', (
    tester,
  ) async {
    await pumpAtTextScale(
      tester,
      child: ProjectSettingsStatsSection(
        project: _thisProject,
        memberCount: 4,
        stats: _stats,
        onPendencyTap: (_) {},
      ),
    );

    final size = tester.getSize(
      find.ancestor(
        of: _breakdownLine(_l10n.recording_pendencyClassification, 3),
        matching: find.byType(InkWell),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48.0));
  });
}
