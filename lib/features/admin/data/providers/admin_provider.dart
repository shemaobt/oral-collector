import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../genre/domain/entities/genre.dart';
import '../../../project/domain/entities/project.dart';
import '../repositories/admin_repository.dart';

// --- Providers ---

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepository(),
);

final adminNotifierProvider =
    NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);

// --- State ---

class AdminState {
  final AdminStats? stats;
  final List<Project> projects;
  final List<Genre> genres;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.stats,
    this.projects = const [],
    this.genres = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    AdminStats? stats,
    List<Project>? projects,
    List<Genre>? genres,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      projects: projects ?? this.projects,
      genres: genres ?? this.genres,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// --- Notifier ---

class AdminNotifier extends Notifier<AdminState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminState build() => const AdminState();

  /// Fetch all admin data: stats, projects, and genres.
  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchAllProjects(),
        _repo.fetchAllGenres(),
      ]);

      state = AdminState(
        stats: results[0] as AdminStats,
        projects: results[1] as List<Project>,
        genres: results[2] as List<Genre>,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Create a new genre and refresh genres list.
  Future<bool> createGenre({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    try {
      await _repo.createGenre(
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Update an existing genre and refresh genres list.
  Future<bool> updateGenre(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateGenre(id, data);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Delete a genre and refresh genres list.
  Future<bool> deleteGenre(String id) async {
    try {
      await _repo.deleteGenre(id);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Create a subcategory and refresh genres list.
  Future<bool> createSubcategory({
    required String genreId,
    required String name,
    String? description,
  }) async {
    try {
      await _repo.createSubcategory(
        genreId: genreId,
        name: name,
        description: description,
      );
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Delete a subcategory and refresh genres list.
  Future<bool> deleteSubcategory(String id) async {
    try {
      await _repo.deleteSubcategory(id);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
