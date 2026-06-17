import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../data/server_to_local_recording.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/repositories/recording_api_repository.dart';
import 'recordings_list_state.dart';

/// Outcome of [RecordingsListNotifier.deleteRecording], so the screen can pick
/// the right snackbar without re-deriving it from an exception.
enum DeleteRecordingResult { ok, forbidden, failed }

const _pageSize = 50;

final recordingsListNotifierProvider =
    NotifierProvider<RecordingsListNotifier, RecordingsListState>(
      RecordingsListNotifier.new,
    );

typedef _FetchResult = ({
  List<LocalRecording> merged,
  bool hasMore,
  int serverOffset,
});

class RecordingsListNotifier extends Notifier<RecordingsListState> {
  RecordingApiRepository get _apiRepo =>
      ref.read(recordingApiRepositoryProvider);
  LocalRecordingRepository get _localRepo =>
      ref.read(localRecordingRepositoryProvider);

  int _serverOffset = 0;
  // Bumped on each fetchRecordings; a fetch/loadMore whose generation no longer
  // matches discards its result instead of clobbering a newer fetch.
  int _fetchGeneration = 0;

  @override
  RecordingsListState build() => const RecordingsListState();

  Future<void> fetchRecordings() async {
    final gen = ++_fetchGeneration;
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    // Reset isLoadingMore here so a superseded in-flight loadMore that bails on
    // the generation check does not leave the flag stuck true.
    state = state.copyWith(isLoading: true, isLoadingMore: false);

    if (!ref.read(syncNotifierProvider).isOnline) {
      final local = await _loadLocal(projectId);
      if (gen != _fetchGeneration) return;
      _serverOffset = 0;
      state = state.copyWith(
        recordings: local ?? state.recordings,
        isLoading: false,
        hasMore: false,
      );
      return;
    }

    try {
      final result = await _fetchAndMerge(projectId);
      if (gen != _fetchGeneration) return;
      _serverOffset = result.serverOffset;
      state = state.copyWith(
        recordings: result.merged,
        isLoading: false,
        hasMore: result.hasMore,
      );
    } catch (e, st) {
      _reportUnexpected(e, st);
      final local = await _loadLocal(projectId);
      if (gen != _fetchGeneration) return;
      _serverOffset = 0;
      state = state.copyWith(
        recordings: local ?? state.recordings,
        isLoading: false,
        hasMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    // Bail while a full fetchRecordings is in flight (isLoading): it will reset
    // the list and _serverOffset on apply, so a page fetched against the
    // current offset would be stale and silently drop records.
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return;

    if (!ref.read(syncNotifierProvider).isOnline) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    final gen = _fetchGeneration;
    state = state.copyWith(isLoadingMore: true);

    try {
      final serverPage = await _apiRepo.listRecordings(
        projectId,
        offset: _serverOffset,
        limit: _pageSize,
        userId: state.selectedUserId,
        storytellerId: state.selectedStorytellerId,
      );
      // A fetchRecordings started after us reset the list and offset; applying
      // this page now would append a stale page, so discard it.
      if (gen != _fetchGeneration) return;

      final hasMore = serverPage.length >= _pageSize;
      _serverOffset += serverPage.length;

      final newPageIds = serverPage.map((s) => s.id).toSet();
      final existingIds = state.recordings.map((r) => r.id).toSet();
      final newServerAsLocal = _convertServerRecordings(
        serverPage,
      ).where((r) => !existingIds.contains(r.id)).toList();
      final currentRecordings = List<LocalRecording>.from(state.recordings)
        ..removeWhere(
          (r) => r.serverId != null && newPageIds.contains(r.serverId),
        )
        ..addAll(newServerAsLocal);

      state = state.copyWith(
        recordings: currentRecordings,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (e, st) {
      _reportUnexpected(e, st);
      if (gen != _fetchGeneration) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void patchRecordingTitle(String recordingId, String title) {
    final updated = state.recordings
        .map((r) => r.id == recordingId ? r.copyWith(title: Value(title)) : r)
        .toList();
    state = state.copyWith(recordings: updated);
  }

  /// Hard-deletes a recording: remotely (only when it has a [serverId]), then
  /// the local row and the audio file, then drops it from state. On a remote
  /// failure for a synced item nothing local is touched, so the row and file
  /// survive for a retry.
  Future<DeleteRecordingResult> deleteRecording(
    LocalRecording recording,
  ) async {
    final serverId = recording.serverId;
    if (serverId != null) {
      try {
        await _apiRepo.deleteRecording(serverId);
      } on ForbiddenException {
        return DeleteRecordingResult.forbidden;
      } catch (e, st) {
        _reportUnexpected(e, st);
        return DeleteRecordingResult.failed;
      }
    }
    // The list shows the server-converted copy (id == serverId, empty
    // localFilePath); a locally-created+uploaded row keeps its own local id.
    // Resolve the real local row so both it and its audio file are removed and
    // the row can't resurrect on the next merge.
    final localRow =
        await _localRepo.getRecordingById(recording.id) ??
        (serverId != null
            ? await _localRepo.getRecordingByServerId(serverId)
            : null);
    await _localRepo.deleteRecording(localRow?.id ?? recording.id);
    final path = localRow?.localFilePath ?? recording.localFilePath;
    if (path.isNotEmpty) {
      try {
        await file_ops.deleteFile(path);
      } on Exception catch (e, st) {
        // Best-effort: a missing/locked file must not abort the row delete.
        _reportUnexpected(e, st);
      }
    }
    state = state.copyWith(
      recordings: state.recordings.where((r) => r.id != recording.id).toList(),
    );
    return DeleteRecordingResult.ok;
  }

  Future<_FetchResult> _fetchAndMerge(String projectId) async {
    final serverRecordings = await _apiRepo.listRecordings(
      projectId,
      offset: 0,
      limit: _pageSize,
      userId: state.selectedUserId,
      storytellerId: state.selectedStorytellerId,
    );
    List<LocalRecording> localRecordings;
    try {
      localRecordings = await _localRepo.getAllRecordings(projectId);
    } catch (e, st) {
      _reportUnexpected(e, st);
      localRecordings = const [];
    }

    final serverIds = {for (final s in serverRecordings) s.id};
    final localOnly = localRecordings
        .where((r) => r.serverId == null || !serverIds.contains(r.serverId))
        .toList();

    final merged = [...localOnly, ..._convertServerRecordings(serverRecordings)]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return (
      merged: merged,
      hasMore: serverRecordings.length >= _pageSize,
      serverOffset: serverRecordings.length,
    );
  }

  List<LocalRecording> _convertServerRecordings(
    List<ServerRecording> recordings,
  ) {
    return recordings.map(serverRecordingToLocal).toList();
  }

  Future<List<LocalRecording>?> _loadLocal(String projectId) async {
    try {
      return await _localRepo.getAllRecordings(projectId);
    } catch (e, st) {
      _reportUnexpected(e, st);
      return null;
    }
  }

  void setGenreFilter(String? genreId) {
    if (genreId == null) {
      state = state.copyWith(clearGenreId: true);
    } else {
      state = state.copyWith(selectedGenreId: genreId);
    }
  }

  void setSubcategoryFilter(String? subcategoryId) {
    if (subcategoryId == null || subcategoryId.isEmpty) {
      state = state.copyWith(clearSubcategoryId: true);
    } else {
      state = state.copyWith(selectedSubcategoryId: subcategoryId);
    }
  }

  void setStatusFilter(StatusFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> setStorytellerFilter(String? storytellerId) async {
    if (storytellerId == null) {
      state = state.copyWith(clearStorytellerId: true);
    } else {
      state = state.copyWith(selectedStorytellerId: storytellerId);
    }
    await fetchRecordings();
  }

  Future<void> setUserFilter(String? userId) async {
    if (userId == null) {
      state = state.copyWith(clearUserId: true);
    } else {
      state = state.copyWith(selectedUserId: userId);
    }
    await fetchRecordings();
  }

  Future<void> clearAllFilters() async {
    state = state.copyWith(
      selectedFilter: StatusFilter.all,
      clearGenreId: true,
      clearSubcategoryId: true,
      clearStorytellerId: true,
      clearUserId: true,
    );
    await fetchRecordings();
  }

  Future<int?> clearStaleRecordings() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return 0;

    // null (not 0) signals "didn't run because offline" so the screen can
    // distinguish a real "0 deleted" success from a no-op fail-fast.
    if (!ref.read(syncNotifierProvider).isOnline) return null;

    final serverDeleted = await _apiRepo.clearStaleRecordings(projectId);
    await _localRepo.deleteStaleRecordings(projectId);
    await fetchRecordings();
    return serverDeleted;
  }

  void _reportUnexpected(Object error, StackTrace stackTrace) {
    // 401 é sessão expirada esperada (tratada por refresh/login alhures);
    // só erros inesperados vão à telemetria.
    if (error is UnauthorizedException) return;
    ref.read(errorReporterProvider).reportError(error, stackTrace);
  }
}
