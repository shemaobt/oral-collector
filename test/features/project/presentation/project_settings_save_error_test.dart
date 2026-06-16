// ENG-104: when a project save fails, the user must see the (localized) error
// instead of a false "updated" confirmation. The notifier captures the failure
// into state.error without rethrowing, so the screen must read state.error
// rather than relying on a try/catch that never fires.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/entities/project_update.dart';
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
  @override
  Future<Project> getProject(String id) async => _project;

  @override
  Future<ProjectStats> getProjectStats(String projectId) async =>
      const ProjectStats();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier({required bool failOnUpdate})
    : _failOnUpdate = failOnUpdate;

  final bool _failOnUpdate;

  @override
  ProjectState build() => const ProjectState(projects: [_project]);

  @override
  Future<void> updateProject(String id, ProjectUpdate update) async {
    // Mirror the real notifier: capture the failure into state.error, do not
    // rethrow.
    if (_failOnUpdate) {
      state = state.copyWith(error: const ServerException(statusCode: 500));
    }
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
}

List<Override> _overrides({required bool failOnUpdate}) => [
  syncNotifierProvider.overrideWith(_FakeSyncNotifier.new),
  projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
  projectNotifierProvider.overrideWith(
    () => _FakeProjectNotifier(failOnUpdate: failOnUpdate),
  ),
  roleNotifierProvider.overrideWith(_FakeRoleNotifier.new),
  memberNotifierProvider.overrideWith(_FakeMemberNotifier.new),
];

Future<void> _pumpAndSave(
  WidgetTester tester, {
  required bool failOnUpdate,
}) async {
  await pumpAtTextScale(
    tester,
    overrides: _overrides(failOnUpdate: failOnUpdate),
    child: const ProjectSettingsScreen(projectId: 'p1'),
  );
  // Let the deferred _fetchAll/_loadProject microtasks resolve and render form.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }

  // Editing the name enables the save button (AnimatedOpacity 0 -> 1).
  await tester.enterText(find.byType(TextFormField).first, 'New Name');
  await tester.pump(const Duration(milliseconds: 300));

  await tester.tap(
    find.widgetWithText(ElevatedButton, _l10n.projectSettings_saveChanges),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'save failure surfaces the localized error, not a false success',
    (tester) async {
      await _pumpAndSave(tester, failOnUpdate: true);

      expect(find.text(_l10n.error_serverFailure), findsOneWidget);
      expect(find.text(_l10n.projectSettings_updated), findsNothing);
    },
  );

  testWidgets('save success surfaces the updated confirmation', (tester) async {
    await _pumpAndSave(tester, failOnUpdate: false);

    expect(find.text(_l10n.projectSettings_updated), findsOneWidget);
    expect(find.text(_l10n.error_serverFailure), findsNothing);
  });
}
