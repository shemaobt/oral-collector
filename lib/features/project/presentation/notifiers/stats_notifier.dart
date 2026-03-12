import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../data/providers.dart';
import '../../domain/repositories/stats_repository.dart';
import 'stats_state.dart';

final statsNotifierProvider = NotifierProvider<StatsNotifier, StatsState>(
  StatsNotifier.new,
);

class StatsNotifier extends Notifier<StatsState> {
  StatsRepository get _repo => ref.read(statsRepositoryProvider);

  @override
  StatsState build() => const StatsState();

  Future<void> fetchGenreStats(String projectId) async {
    state = state.copyWith(isLoading: true);

    try {
      final genreStats = await _repo.fetchGenreStats(projectId);
      state = state.copyWith(genreStats: genreStats, isLoading: false);
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      ref.read(authNotifierProvider.notifier).handleUnauthorized();
    } on Exception {
      state = state.copyWith(isLoading: false);
    }
  }
}
