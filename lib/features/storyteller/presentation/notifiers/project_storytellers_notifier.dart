import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repositories/local_storyteller_repository.dart';
import '../../domain/entities/storyteller.dart';
import '../../domain/repositories/storyteller_repository.dart';
import 'project_storytellers_state.dart';

final projectStorytellersNotifierProvider =
    NotifierProvider<ProjectStorytellersNotifier, ProjectStorytellersState>(
      ProjectStorytellersNotifier.new,
    );

class ProjectStorytellersNotifier extends Notifier<ProjectStorytellersState> {
  StorytellerRepository get _api => ref.read(storytellerApiRepositoryProvider);
  LocalStorytellerRepository get _local =>
      ref.read(localStorytellerRepositoryProvider);

  @override
  ProjectStorytellersState build() => const ProjectStorytellersState();

  Future<void> fetch(String projectId) async {
    state = state.copyWith(
      projectId: projectId,
      isLoading: true,
      clearError: true,
    );

    final cached = await _local.getByProject(projectId);
    if (cached.isNotEmpty) {
      state = state.copyWith(storytellers: cached);
    }

    try {
      final items = await _api.listByProject(projectId);
      await _local.upsertAll(items, projectId);
      state = state.copyWith(storytellers: items, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Storyteller?> create({
    required String projectId,
    required String name,
    required StorytellerSex sex,
    int? age,
    String? location,
    String? dialect,
    required bool externalAcceptanceConfirmed,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final created = await _api.create(
        projectId: projectId,
        name: name,
        sex: sex,
        age: age,
        location: location,
        dialect: dialect,
        externalAcceptanceConfirmed: externalAcceptanceConfirmed,
      );
      final next = [...state.storytellers, created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _local.upsertAll(next, projectId);
      state = state.copyWith(storytellers: next, isMutating: false);
      return created;
    } on Exception catch (e) {
      state = state.copyWith(
        isMutating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<Storyteller?> update(
    String id, {
    String? name,
    StorytellerSex? sex,
    int? age,
    String? location,
    String? dialect,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final updated = await _api.update(
        id,
        name: name,
        sex: sex,
        age: age,
        location: location,
        dialect: dialect,
      );
      final next =
          state.storytellers.map((s) => s.id == id ? updated : s).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      final pid = state.projectId;
      if (pid != null) {
        await _local.upsertAll(next, pid);
      }
      state = state.copyWith(storytellers: next, isMutating: false);
      return updated;
    } on Exception catch (e) {
      state = state.copyWith(
        isMutating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _api.delete(id);
      final next = state.storytellers.where((s) => s.id != id).toList();
      await _local.delete(id);
      state = state.copyWith(storytellers: next, isMutating: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isMutating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
