import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recording/data/providers.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../project/presentation/notifiers/stats_notifier.dart';
import 'home_state.dart';

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    return HomeState(greeting: _computeGreeting());
  }

  String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String greetingFor(String? displayName) {
    final base = state.greeting;
    if (displayName != null && displayName.isNotEmpty) {
      return '$base, ${displayName.split(' ').first}';
    }
    return base;
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isRefreshing: true);
    await _loadLocalPending();
    state = state.copyWith(isRefreshing: false, greeting: _computeGreeting());
  }

  Future<void> _loadLocalPending() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return;

    final repo = ref.read(localRecordingRepositoryProvider);
    final pending = await repo.getPendingUploads();
    final forProject = pending.where((r) => r.projectId == projectId);

    state = state.copyWith(
      localPendingCount: forProject.length,
      localPendingDuration: forProject.fold<double>(
        0.0,
        (sum, r) => sum + r.durationSeconds,
      ),
    );
    computeTotals();
  }

  void computeTotals() {
    int recordings = state.localPendingCount;
    double duration = state.localPendingDuration;
    for (final stat in ref.read(statsNotifierProvider).genreStats.values) {
      recordings += stat.recordingCount;
      duration += stat.totalDurationSeconds;
    }
    state = state.copyWith(
      totalRecordings: recordings,
      totalDuration: duration,
    );
  }
}
