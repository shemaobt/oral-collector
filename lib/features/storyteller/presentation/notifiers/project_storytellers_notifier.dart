import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sync/presentation/notifiers/sync_notifier.dart';
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

  // Dedupe concurrent fetch() calls for the same project — when both
  // StorytellersListScreen and StorytellerPicker are mounted, both register
  // a reconnect listener and both fire on the same connectivity flip.
  // We don't want two API hits for that. Project switches bypass.
  String? _inflightProjectId;

  @override
  ProjectStorytellersState build() => const ProjectStorytellersState();

  Future<void> fetch(String projectId) async {
    if (_inflightProjectId == projectId) return;
    _inflightProjectId = projectId;
    try {
      state = state.copyWith(
        projectId: projectId,
        isLoading: true,
        clearError: true,
      );

      final cached = await _local.getByProject(projectId);
      state = state.copyWith(storytellers: cached);

      if (!ref.read(syncNotifierProvider).isOnline) {
        state = state.copyWith(isLoading: false);
        return;
      }

      try {
        final items = await _api.listByProject(projectId);
        await _local.upsertAll(items, projectId);
        final merged = await _local.getByProject(projectId);
        state = state.copyWith(storytellers: merged, isLoading: false);
      } on Exception catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      _inflightProjectId = null;
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
      final localId = _newLocalStorytellerId();
      final local = Storyteller(
        id: localId,
        projectId: projectId,
        name: name,
        sex: sex,
        age: age,
        location: location,
        dialect: dialect,
        externalAcceptanceConfirmed: externalAcceptanceConfirmed,
        createdAt: DateTime.now(),
      );
      await _local.insertLocal(local, syncStatus: 'local');
      final next = [...state.storytellers, local]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = state.copyWith(storytellers: next, isMutating: false);
      return local;
    } on Exception catch (e) {
      state = state.copyWith(
        isMutating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  String _newLocalStorytellerId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = math.Random.secure()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return 'stl_${millis}_$rand';
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
      final row = await _local.getRowById(id);
      final isLocalOnly = row != null && row.syncStatus != 'synced';
      if (!isLocalOnly) {
        await _api.delete(id);
      }
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
