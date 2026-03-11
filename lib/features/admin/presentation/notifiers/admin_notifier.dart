import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../genre/domain/entities/genre.dart';
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

    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchAllProjects(),
        _repo.fetchAllGenres(),
        _repo.fetchCleaningQueue(),
      ]);

      state = AdminState(
        stats: results[0] as AdminStats,
        projects: results[1] as List<Project>,
        genres: results[2] as List<Genre>,
        cleaningQueue: results[3] as List<Recording>,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refreshCleaningQueue() async {
    try {
      final queue = await _repo.fetchCleaningQueue();
      state = state.copyWith(cleaningQueue: queue);
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> triggerClean(String recordingId) async {
    try {
      await _repo.triggerClean(recordingId);
      await refreshCleaningQueue();
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<int> triggerBatchClean(List<String> recordingIds) async {
    int successCount = 0;
    for (final id in recordingIds) {
      try {
        await _repo.triggerClean(id);
        successCount++;
      } on Exception {
        // ignore individual failure, continue batch
      }
    }
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
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

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
