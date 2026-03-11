import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/project.dart';
import '../../../recording/domain/entities/recording.dart';
import '../entities/admin_stats.dart';

abstract class AdminRepository {
  Future<AdminStats> fetchStats();
  Future<List<Project>> fetchAllProjects();
  Future<List<Genre>> fetchAllGenres();
  Future<Genre> createGenre({
    required String name,
    String? description,
    String? icon,
    String? color,
  });
  Future<Genre> updateGenre(String id, Map<String, dynamic> data);
  Future<void> deleteGenre(String id);
  Future<void> createSubcategory({
    required String genreId,
    required String name,
    String? description,
  });
  Future<void> deleteSubcategory(String id);
  Future<List<Recording>> fetchCleaningQueue();
  Future<void> triggerClean(String recordingId);
}
