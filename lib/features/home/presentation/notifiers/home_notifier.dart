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
  int _localOnlyCount = 0;
  double _localOnlyDuration = 0;
  int _localUnclassifiedCount = 0;

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
    await _loadLocalStats();
    state = state.copyWith(isRefreshing: false, greeting: _computeGreeting());
  }

  Future<void> _loadLocalStats() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return;

    _localOnlyCount = 0;
    _localOnlyDuration = 0;
    _localUnclassifiedCount = 0;

    if (!kIsWeb) {
      final repo = ref.read(localRecordingRepositoryProvider);
      final localOnly = await repo.getLocalOnlyStats(projectId);
      _localOnlyCount = localOnly.count;
      _localOnlyDuration = localOnly.durationSeconds;

      final unclassified = await repo.getLocalUnclassifiedStats(projectId);
      _localUnclassifiedCount = unclassified.count;
    }

    computeTotals();
  }

  void computeTotals() {
    // Two addends that cannot overlap: what only this device holds, plus what
    // the server reports. See ENG-355.
    int recordings = _localOnlyCount;
    double duration = _localOnlyDuration;
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
