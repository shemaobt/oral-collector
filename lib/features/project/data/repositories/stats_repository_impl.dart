import 'dart:convert';

import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../domain/entities/stats.dart';
import '../../domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  final AuthenticatedClient _client;

  StatsRepositoryImpl({required AuthenticatedClient client}) : _client = client;

  @override
  Future<Map<String, GenreStat>> fetchGenreStats(String projectId) async {
    final response = await _client.get(
      '/api/oc/projects/$projectId/genre-stats',
    );
    guardResponse(response);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseGenreStats(data);
  }

  Map<String, GenreStat> _parseGenreStats(Map<String, dynamic> data) {
    final genresList = data['genres'] as List<dynamic>? ?? [];
    final subcategoriesList = data['subcategories'] as List<dynamic>? ?? [];

    final subcatsByGenre = _groupSubcategoryStats(subcategoriesList);
    return _buildGenreStats(genresList, subcatsByGenre);
  }

  Map<String, Map<String, SubcategoryStat>> _groupSubcategoryStats(
    List<dynamic> subcategoriesList,
  ) {
    final subcatsByGenre = <String, Map<String, SubcategoryStat>>{};
    for (final sub in subcategoriesList) {
      final map = sub as Map<String, dynamic>;
      final genreId = map['genre_id'] as String;
      final subcatId = map['subcategory_id'] as String;
      subcatsByGenre.putIfAbsent(genreId, () => {});
      subcatsByGenre[genreId]![subcatId] = SubcategoryStat(
        subcategoryId: subcatId,
        totalDurationSeconds: (map['duration_seconds'] as num).toDouble(),
        recordingCount: map['recording_count'] as int,
      );
    }
    return subcatsByGenre;
  }

  Map<String, GenreStat> _buildGenreStats(
    List<dynamic> genresList,
    Map<String, Map<String, SubcategoryStat>> subcatsByGenre,
  ) {
    final genreStats = <String, GenreStat>{};
    for (final genre in genresList) {
      final map = genre as Map<String, dynamic>;
      final genreId = map['genre_id'] as String;
      genreStats[genreId] = GenreStat(
        genreId: genreId,
        totalDurationSeconds: (map['duration_seconds'] as num).toDouble(),
        recordingCount: map['recording_count'] as int,
        subcategories: subcatsByGenre[genreId] ?? const {},
      );
    }
    return genreStats;
  }
}
