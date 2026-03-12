import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/project.dart';
import '../../../recording/domain/entities/recording.dart';
import '../../domain/entities/admin_stats.dart';

class AdminState {
  final AdminStats? stats;
  final List<Project> projects;
  final List<Genre> genres;
  final List<Recording> cleaningQueue;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.stats,
    this.projects = const [],
    this.genres = const [],
    this.cleaningQueue = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    AdminStats? stats,
    List<Project>? projects,
    List<Genre>? genres,
    List<Recording>? cleaningQueue,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      projects: projects ?? this.projects,
      genres: genres ?? this.genres,
      cleaningQueue: cleaningQueue ?? this.cleaningQueue,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
