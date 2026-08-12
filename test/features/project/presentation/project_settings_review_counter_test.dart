/// The review counter has to survive the trip from the repository to the
/// screen (ENG-374).
///
/// Every other test for this feature stops at the widget or the entity, so the
/// screen could fetch the stats, hold them, and hand the section nothing —
/// and all of them would still pass. That is not hypothetical: it happened
/// once during review, and 53 green tests said nothing.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_state.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/project/presentation/project_settings_screen.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../support/text_scale.dart';

final _l10n = AppLocalizationsEn();

const _project = Project(
  id: 'p1',
  name: 'Original Name',
  languageId: 'l1',
  languageName: 'English',
  languageCode: 'en',
);

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({this.stats, this.throwOnStats = false});

  final ProjectStats? stats;
  final bool throwOnStats;

  @override
  Future<Project> getProject(String id) async => _project;

  @override
  Future<ProjectStats> getProjectStats(String projectId) async {
    if (throwOnStats) throw const ServerException(statusCode: 500);
    return stats ?? const ProjectStats();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(projects: [_project]);
}

class _FakeRoleNotifier extends RoleNotifier {
  @override
  RoleState build() => const RoleState();

  @override
  bool canManageProject(String projectId) => true;
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
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeProjectRepository repo,
) async {
  await pumpAtTextScale(
    tester,
    overrides: [
      syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
      projectRepositoryProvider.overrideWithValue(repo),
      projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
      roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
      memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
    ],
    child: const ProjectSettingsScreen(projectId: 'p1'),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('what the server counted reaches the screen', (tester) async {
    await _pumpScreen(
      tester,
      _FakeProjectRepository(
        stats: const ProjectStats(
          totalRecordings: 12,
          recordingsWithReviewFlags: 3,
          reviewFlagCounts: {'missing_classification': 3},
        ),
      ),
    );

    expect(find.text(_l10n.projectStats_needsDetails), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the screen shows recordings, not the sum of their gaps', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      _FakeProjectRepository(
        stats: const ProjectStats(
          totalRecordings: 12,
          // Four gaps across three recordings: one of them is missing two
          // fields. Summing the map answers 4, which is wrong and believable.
          recordingsWithReviewFlags: 3,
          reviewFlagCounts: {
            'missing_classification': 3,
            'missing_storyteller': 1,
          },
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('a project with nothing outstanding still renders the row', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      _FakeProjectRepository(
        stats: const ProjectStats(
          totalRecordings: 12,
          recordingsWithReviewFlags: 0,
        ),
      ),
    );

    expect(find.text(_l10n.projectStats_needsDetails), findsOneWidget);
  });

  testWidgets('a failed stats call costs the counter, not the screen', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeProjectRepository(throwOnStats: true));

    // Best-effort: the counter is the only thing that depends on the fetch.
    expect(find.text(_l10n.projectStats_needsDetails), findsNothing);
    expect(find.text(_l10n.projectSettings_saveChanges), findsOneWidget);
  });
}
