import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_stats_provider.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _CountingStatsRepo implements ProjectRepository {
  int asked = 0;

  @override
  Future<ProjectStats> getProjectStats(String projectId) async {
    asked++;
    return const ProjectStats();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _QuietSync extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);
}

void main() {
  test('a second visit to the list asks the server for the counts again, '
      'because a web save never ends a sync round', () async {
    final repo = _CountingStatsRepo();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repo),
        syncNotifierProvider.overrideWith(_QuietSync.new),
      ],
    );
    addTearDown(container.dispose);

    final firstVisit = container.listen(projectStatsProvider('p1'), (_, _) {});
    await container.read(projectStatsProvider('p1').future);
    firstVisit.close();
    await Future<void>.delayed(Duration.zero);

    container.listen(projectStatsProvider('p1'), (_, _) {});
    await container.read(projectStatsProvider('p1').future);

    expect(
      repo.asked,
      2,
      reason: 'o contador da visita anterior ficava valendo para sempre',
    );
  });
}
