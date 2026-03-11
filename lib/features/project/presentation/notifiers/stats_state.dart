import '../../domain/entities/stats.dart';

class StatsState {
  final Map<String, GenreStat> genreStats;
  final bool isLoading;

  const StatsState({this.genreStats = const {}, this.isLoading = false});

  StatsState copyWith({Map<String, GenreStat>? genreStats, bool? isLoading}) {
    return StatsState(
      genreStats: genreStats ?? this.genreStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
