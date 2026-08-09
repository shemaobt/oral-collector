import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/util/bounded_concurrency.dart';
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
import '../../domain/server_deletion_policy.dart';
import '../trim_load_error.dart';
import 'recordings_list_state.dart';

/// Outcome of [RecordingsListNotifier.deleteRecording], so the screen can pick
/// the right snackbar without re-deriving it from an exception.
enum DeleteRecordingResult { ok, forbidden, failed }

const _pageSize = 50;

/// Confirmations run in parallel up to this many at once; the deletions they
/// authorise stay serial.
const _confirmDeletedConcurrency = 6;

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
  // Every server id the current sweep has seen, stamped with the project it
  // was collected under. Null while there is no sweep worth finishing.
  ({String projectId, Set<String> serverIds})? _sweep;

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
      final result = await _fetchAndMerge(projectId, gen);
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

      final erased = await _advanceSweep(
        projectId: projectId,
        page: serverPage,
        hasMore: hasMore,
        gen: gen,
      );
      if (gen != _fetchGeneration) return;
      currentRecordings.removeWhere((r) => erased.contains(r.id));

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

  Future<_FetchResult> _fetchAndMerge(String projectId, int gen) async {
    // Read the filters once, before the await, the way projectId already is:
    // what follows has to judge the response against the filters it was
    // actually requested with. Re-reading state afterwards lets a slow filtered
    // response be mistaken for a whole-project answer once the user clears the
    // filter, and the generation counter in the caller does not help — it
    // discards the stale list, not the deletes done on the way to building it.
    final userId = state.selectedUserId;
    final storytellerId = state.selectedStorytellerId;
    final reviewFlag = _reviewFlagCode;

    final serverRecordings = await _apiRepo.listRecordings(
      projectId,
      offset: 0,
      limit: _pageSize,
      userId: userId,
      storytellerId: storytellerId,
      reviewFlag: reviewFlag,
    );
    // A pendency filter takes the server's answer alone. The counts that send
    // the user here only cover uploaded and verified recordings, so a row that
    // has never left this phone was never part of the number tapped; merging
    // the device in would pad the list with recordings the filter never
    // considered.
    final localRecordings = reviewFlag != null
        ? const <LocalRecordingEntity>[]
        : (await _loadLocal(projectId)) ?? const <LocalRecordingEntity>[];

    final serverIds = {for (final s in serverRecordings) s.id};
    var localOnly = localRecordings
        .where((r) => r.serverId == null || !serverIds.contains(r.serverId))
        .toList();

    final unfiltered =
        userId == null && storytellerId == null && reviewFlag == null;

    // This page is where a sweep begins, so a project past one page can heal
    // once pagination reaches the end instead of never (ENG-400). It is stamped
    // with the project it was collected under; a filtered fetch installs no
    // sweep, and a fetch a newer one already superseded installs nothing.
    if (gen == _fetchGeneration) {
      _sweep = unfiltered
          ? (projectId: projectId, serverIds: {...serverIds})
          : null;
    }

    // What follows decides who is *asked about*, not who is deleted — the
    // erase confirms every candidate individually. These conditions are what
    // keep that list short: under a filter, or with pages still to come, most
    // of the project is missing from the answer for reasons that have nothing
    // to do with deletion, and asking about all of it would be a request storm
    // against a server that already answered. An empty response is excluded on
    // top of that: a lost permission, a mis-scoped query and a genuinely empty
    // project are indistinguishable, so it is no reason to suspect anything.
    final sweptWholeProject =
        unfiltered &&
        serverRecordings.isNotEmpty &&
        serverRecordings.length < _pageSize;
    if (sweptWholeProject) {
      final erased = await _eraseDeletedOnServer(localOnly, gen: gen);
      if (erased.isNotEmpty) {
        localOnly = localOnly.where((r) => !erased.contains(r.id)).toList();
      }
    }

    final merged = [...localOnly, ..._convertServerRecordings(serverRecordings)]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return (
      merged: merged,
      hasMore: serverRecordings.length >= _pageSize,
      serverOffset: serverRecordings.length,
    );
  }

  /// Feeds a paginated page into the sweep [_fetchAndMerge] started and, once
  /// the sweep ends, hands what no page showed to [_eraseDeletedOnServer] as
  /// *candidates*. Returns the ids actually erased, so the caller can drop them
  /// from the list too.
  ///
  /// A project past one page never heals from the first page alone, which is
  /// the whole point of accumulating (ENG-400). What the accumulation is not is
  /// proof: neither set holds still across several round trips, so the union
  /// only narrows who gets asked about individually.
  Future<Set<String>> _advanceSweep({
    required String projectId,
    required List<ServerRecording> page,
    required bool hasMore,
    required int gen,
  }) async {
    final sweep = _sweep;
    // Another project's pages answer about other recordings, so they never join
    // this sweep. A filter is handled upstream: a filtered fetch installs no
    // sweep, so there is nothing here to feed. So is a newer fetch — it
    // installs a sweep of its own and the caller drops pages older than it.
    if (sweep == null || projectId != sweep.projectId) return const {};
    sweep.serverIds.addAll(page.map((s) => s.id));

    // Mid-pagination absence means nothing: the recording may be on a page
    // ahead. Only the last page closes the sweep.
    if (hasMore) return const {};
    _sweep = null;
    // Defence in depth, unreachable as written: page zero being empty ends the
    // pagination before any of this. A union of nothing is not an answer about
    // anything, the way an empty first page is not (see _fetchAndMerge).
    if (sweep.serverIds.isEmpty) return const {};

    final local = await _loadLocal(projectId) ?? const <LocalRecordingEntity>[];
    // A refresh landing while the local read was in flight means the caller
    // will discard our list, so this sweep has nothing left to do. Purely an
    // early-out: the erase cuts on the generation too, before each confirmation
    // and again before each delete, which is what actually keeps rows the
    // screen would go on showing from being deleted under it.
    if (gen != _fetchGeneration) return const {};
    return _eraseDeletedOnServer(
      local.where((r) => !sweep.serverIds.contains(r.serverId)).toList(),
      gen: gen,
    );
  }

  /// Drops the rows the server hard-deleted (row + audio file) and returns
  /// their ids.
  ///
  /// Missing from a listing is a suspicion, not a verdict. Neither set holds
  /// still while a sweep runs: an upload landing after page zero puts a live
  /// recording in a window already read, and a delete on the server shifts the
  /// offset window so the next page skips a row that is still there. Both end
  /// with a recording absent from every page and present on the server. So each
  /// candidate is confirmed individually before anything is destroyed — a
  /// listing can be stale or mis-windowed, a 404 for one id cannot.
  ///
  /// Only what the server acknowledged is a candidate at all
  /// ([canEraseAsDeletedOnServer]), and since ENG-399 that gate no longer means
  /// the row is a redundant copy: a metadata edit made offline lives in the
  /// local row, and until the outbox drains it (ENG-403) this device holds the
  /// only copy of it — so a false positive costs the user's edits outright and
  /// not just a cached copy of the audio. The outbox narrowed that window; it
  /// did not close it, because the edit is owed for exactly as long as the
  /// device cannot reach the server, which is when a sweep is least reliable.
  ///
  /// When the deletion is real the pendency goes with the row, which is
  /// correct: the recording it described no longer exists, so there is nothing
  /// left to update.
  Future<Set<String>> _eraseDeletedOnServer(
    List<LocalRecordingEntity> candidates, {
    required int gen,
  }) async {
    final erasable = candidates
        .where(
          (r) => canEraseAsDeletedOnServer(
            serverId: r.serverId,
            uploadStatus: r.uploadStatus,
          ),
        )
        .toList();
    if (erasable.isEmpty) return const {};

    // The confirmations fan out; the deletes stay serial. A server-side cleanup
    // of thirty recordings is thirty round trips, and this runs before the list
    // stops loading, on links where the client has no response timeout at all:
    // in series that is a spinner the length of thirty timeouts. Deleting is
    // local and cheap, so it keeps the one shape that is obviously correct —
    // one row at a time, one set built in one place.
    final confirmations = await mapBounded(
      erasable,
      _confirmDeletedConcurrency,
      (recording) async {
        // A refresh superseded this sweep: whatever is still queued costs
        // nothing and the next sweep will ask again.
        if (gen != _fetchGeneration) return (recording: recording, gone: false);
        return (
          recording: recording,
          gone: await _confirmDeletedOnServer(recording.serverId!),
        );
      },
    );

    final erased = <String>{};
    for (final confirmation in confirmations) {
      if (gen != _fetchGeneration) break;
      if (!confirmation.gone) continue;
      final recording = confirmation.recording;
      await _localRepo.deleteRecording(recording.id);
      erased.add(recording.id);
      if (recording.localFilePath.isNotEmpty) {
        try {
          await file_ops.deleteFile(recording.localFilePath);
        } on Exception catch (e, st) {
          // Best-effort: a missing/locked file must not abort the row delete.
          _reportUnexpected(e, st);
        }
      }
    }
    return erased;
  }

  /// Asks the server about this one recording. Only a 404 confirms the delete;
  /// an answer, a refusal or an unreachable server all leave the row alone, the
  /// same reading RecordingDetailNotifier applies to a single recording.
  Future<bool> _confirmDeletedOnServer(String serverId) async {
    try {
      await _apiRepo.getRecording(serverId);
      return false;
    } catch (e, st) {
      if (isRecordingNotFound(e)) return true;
      // Not an answer about this recording, so the row stays — but the failure
      // is reported (ENG-102): an endpoint failing systematically would
      // otherwise switch healing off permanently and silently.
      _reportUnexpected(e, st);
      return false;
    }
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
