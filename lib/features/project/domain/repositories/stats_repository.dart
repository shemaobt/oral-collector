import '../entities/stats.dart';

abstract class StatsRepository {
  Future<Map<String, GenreStat>> fetchGenreStats(String projectId);
}
