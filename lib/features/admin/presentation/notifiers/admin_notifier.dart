import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/util/bounded_concurrency.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../genre/domain/entities/genre_update.dart';
import '../../../project/domain/entities/project.dart';
import '../../../recording/domain/entities/recording.dart';
import '../../data/providers.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_state.dart';

final adminNotifierProvider = NotifierProvider<AdminNotifier, AdminState>(
  AdminNotifier.new,
);

class AdminNotifier extends Notifier<AdminState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminState build() => const AdminState();

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (stats, projects, genres, cleaningQueue) = await (
      _repo.fetchStats().then<AdminStats?>((v) => v).catchError((_) => null),
      _repo
          .fetchAllProjects()
          .then<List<Project>?>((v) => v)
          .catchError((_) => null),
      _repo
          .fetchAllGenres()
          .then<List<Genre>?>((v) => v)
          .catchError((_) => null),
      _repo
          .fetchCleaningQueue()
          .then<List<Recording>?>((v) => v)
          .catchError((_) => null),
    ).wait;

    state = AdminState(
      stats: stats ?? state.stats,
      projects: projects ?? state.projects,
      genres: genres ?? state.genres,
      cleaningQueue: cleaningQueue ?? state.cleaningQueue,
      isLoading: false,
    );
  }

  Future<void> refreshCleaningQueue() async {
    try {
      final queue = await _repo.fetchCleaningQueue();
      state = state.copyWith(cleaningQueue: queue);
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
    }
  }

  Future<bool> triggerClean(String recordingId) async {
    try {
      await _repo.triggerClean(recordingId);
      await refreshCleaningQueue();
      return true;
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  static const _batchCleanConcurrency = 6;

  Future<int> triggerBatchClean(List<String> recordingIds) async {
    final outcomes = await mapBounded<String, bool>(
      recordingIds,
      _batchCleanConcurrency,
      (id) async {
        try {
          await _repo.triggerClean(id);
          return true;
        } on Exception {
          return false;
        }
      },
    );
    final successCount = outcomes.where((ok) => ok).length;
    await refreshCleaningQueue();
    return successCount;
  }

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
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<bool> updateGenre(String id, GenreUpdate update) async {
    try {
      await _repo.updateGenre(id, update);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<bool> deleteGenre(String id) async {
    try {
      await _repo.deleteGenre(id);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

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
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<bool> deleteSubcategory(String id) async {
    try {
      await _repo.deleteSubcategory(id);
      final genres = await _repo.fetchAllGenres();
      state = state.copyWith(genres: genres);
      return true;
    } on Exception catch (e, st) {
      _reportUnexpected(e, st);
      state = state.copyWith(error: e);
      return false;
    }
  }

  void _reportUnexpected(Object error, StackTrace stackTrace) {
    // 401 é sessão expirada esperada (tratada por refresh/login alhures);
    // só erros inesperados vão à telemetria.
    if (error is UnauthorizedException) return;
    ref.read(errorReporterProvider).reportError(error, stackTrace);
  }
}
