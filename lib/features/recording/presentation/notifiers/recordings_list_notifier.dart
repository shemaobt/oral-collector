import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/local_recording_to_entity.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../data/server_to_local_recording.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../../domain/entities/review_pendency.dart';
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
  List<LocalRecordingEntity> merged,
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

  String? get _reviewFlagCode {
    final kind = state.selectedReviewFlag;
    return kind == null ? null : reviewFlagCodeFor(kind);
  }

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
      final local = await _localFallback(projectId);
      if (gen != _fetchGeneration) return;
      _serverOffset = 0;
      state = state.copyWith(
        recordings: local ?? state.recordings,
        isLoading: false,
        hasMore: false,
        // Offline is its own story, and the screen tells it differently.
        fetchFailed: false,
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
        fetchFailed: false,
      );
    } catch (e, st) {
      _reportUnexpected(e, st);
      final local = await _localFallback(projectId);
      if (gen != _fetchGeneration) return;
      _serverOffset = 0;
      state = state.copyWith(
        recordings: local ?? state.recordings,
        isLoading: false,
        hasMore: false,
        // The list that comes out of here is not an answer about the project.
        // Without this the screen cannot tell "nothing to do" from "I could
        // not find out", and it picks the reassuring one.
        fetchFailed: true,
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
        reviewFlag: _reviewFlagCode,
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
      final currentRecordings =
          List<LocalRecordingEntity>.from(state.recordings)
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
        .map((r) => r.id == recordingId ? r.copyWith(title: title) : r)
        .toList();
    state = state.copyWith(recordings: updated);
  }

  /// Hard-deletes a recording: remotely (only when it has a [serverId]), then
  /// the local row and the audio file, then drops it from state. On a remote
  /// failure for a synced item nothing local is touched, so the row and file
  /// survive for a retry.
  Future<DeleteRecordingResult> deleteRecording(
    LocalRecordingEntity recording,
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
      reviewFlag: _reviewFlagCode,
    );
    // A pendency filter takes the server's answer alone. The counts that send
    // the user here only cover uploaded and verified recordings, so a row that
    // has never left this phone was never part of the number tapped; merging
    // the device in would pad the list with recordings the filter never
    // considered.
    final localRecordings = state.selectedReviewFlag != null
        ? const <LocalRecordingEntity>[]
        : (await _loadLocal(projectId)) ?? const <LocalRecordingEntity>[];

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

  List<LocalRecordingEntity> _convertServerRecordings(
    List<ServerRecording> recordings,
  ) {
    return recordings
        .map((s) => localRecordingToEntity(serverRecordingToLocal(s)))
        .toList();
  }

  Future<List<LocalRecordingEntity>?> _loadLocal(String projectId) async {
    try {
      final rows = await _localRepo.getAllRecordings(projectId);
      return rows.map(localRecordingToEntity).toList();
    } catch (e, st) {
      _reportUnexpected(e, st);
      return null;
    }
  }

  /// What to show when the server is out of reach.
  ///
  /// Nothing, while a pendency filter is on: only the server can say which
  /// recordings carry a flag, so falling back to the device would put the whole
  /// project on screen underneath a filter chip that says otherwise. An empty
  /// list under a visible filter is legible; a full one silently lies.
  Future<List<LocalRecordingEntity>?> _localFallback(String projectId) async {
    if (state.selectedReviewFlag != null) {
      return const <LocalRecordingEntity>[];
    }
    return _loadLocal(projectId);
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

  /// Narrows the list to one pendency, or widens it back when [kind] is null.
  ///
  /// A server-side filter, unlike genre or status: those sieve the page already
  /// in memory, which would hide every flagged recording past the first page and
  /// put a smaller number on screen than the counter that sent the user here.
  ///
  /// [refresh] is for the screen's initState, which applies the filter and then
  /// refreshes everything itself; fetching here too would ask twice.
  Future<void> setReviewFlagFilter(
    PendencyKind? kind, {
    bool refresh = true,
  }) async {
    if (kind == null) {
      state = state.copyWith(clearReviewFlag: true);
    } else {
      state = state.copyWith(selectedReviewFlag: kind);
    }
    if (refresh) await fetchRecordings();
  }

  Future<void> clearAllFilters() async {
    state = state.copyWith(
      selectedFilter: StatusFilter.all,
      clearGenreId: true,
      clearSubcategoryId: true,
      clearStorytellerId: true,
      clearUserId: true,
      clearReviewFlag: true,
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
