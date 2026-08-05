import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../project/presentation/notifiers/stats_notifier.dart';
import '../../../recording/data/providers.dart';
import '../../../recording/domain/entities/classification.dart';
import 'home_state.dart';

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeNotifier extends Notifier<HomeState> {
  int _localUnclassifiedCount = 0;
  double _localUnclassifiedDuration = 0;

  @override
  HomeState build() {
    return HomeState(greeting: _computeGreeting());
  }

  GreetingPeriod _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return GreetingPeriod.morning;
    if (hour < 17) return GreetingPeriod.afternoon;
    return GreetingPeriod.evening;
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isRefreshing: true);
    await _loadLocalPending();
    state = state.copyWith(isRefreshing: false, greeting: _computeGreeting());
  }

  Future<void> _loadLocalPending() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return;

    var localPendingCount = 0;
    var localPendingDuration = 0.0;
    _localUnclassifiedCount = 0;
    _localUnclassifiedDuration = 0;

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      final pending = await repo.getPendingUploads();
      final forProject = pending.where((r) => r.projectId == projectId);
      localPendingCount = forProject.length;
      localPendingDuration = forProject.fold<double>(
        0.0,
        (sum, r) => sum + r.durationSeconds,
      );

      final unclassifiedStats = await repo.getLocalUnclassifiedStats(projectId);
      _localUnclassifiedCount = unclassifiedStats.count;
      _localUnclassifiedDuration = unclassifiedStats.durationSeconds;
    }

    state = state.copyWith(
      localPendingCount: localPendingCount,
      localPendingDuration: localPendingDuration,
    );
    computeTotals();
  }

  void computeTotals() {
    int recordings = state.localPendingCount + _localUnclassifiedCount;
    double duration = state.localPendingDuration + _localUnclassifiedDuration;
    final genreStats = ref.read(statsNotifierProvider).genreStats;
    for (final stat in genreStats.values) {
      recordings += stat.recordingCount;
      duration += stat.totalDurationSeconds;
    }
    final serverUnclassified =
        genreStats[kUnclassifiedGenreId]?.recordingCount ?? 0;
    state = state.copyWith(
      totalRecordings: recordings,
      totalDuration: duration,
      unclassifiedCount: _localUnclassifiedCount + serverUnclassified,
    );
  }
}
