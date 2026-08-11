import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/app_exception.dart' show ConflictException;
import '../../../../core/observability/error_reporter.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../auth/data/providers/role_provider.dart';
import '../../../project/presentation/notifiers/member_notifier.dart';
import '../../../project/presentation/notifiers/stats_notifier.dart';
import '../../../storyteller/data/providers.dart' as storyteller_providers;
import '../../../storyteller/domain/entities/storyteller.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/local_recording_to_entity.dart';
import '../../data/providers.dart';
import '../../data/recording_heal_companion.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../data/server_to_local_recording.dart';
import '../../data/services/audio_downloader.dart';
import '../../data/services/recording_file_importer.dart';
import '../../data/use_cases/save_recording_description.dart';
import '../../data/use_cases/save_recording_title.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../../domain/entities/pending_metadata_field.dart';
import '../../domain/entities/review_flag.dart';
import '../../domain/entities/update_recording_request.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../../domain/server_deletion_policy.dart';
import '../trim_load_error.dart';
import '../widgets/classify_recording_dialog.dart' show ClassifyResult;
import '../widgets/move_category_dialog.dart' show MoveCategoryResult;
import '../widgets/secondary_classification_fields.dart' show SecondaryValues;
import 'recording_detail_state.dart';
import 'recordings_list_notifier.dart';

/// Outcome the headless notifier hands back to the widget for the metadata
/// mutations (move/classify/secondary/cleaning/edit). The notifier has no
/// BuildContext, so the widget maps each result to its own localized snackbar.
enum RecordingMutationResult {
  success,
  savedLocallyOnly,
  failed,
  forbidden,
  titleConflict,
}

/// What the server did with a metadata write, so the caller can tell a refusal
/// apart from not having reached the server at all (ENG-399).
enum _ServerWrite { accepted, rejected, forbidden, unreachable }

typedef _ServerWriteOutcome = ({
  _ServerWrite status,
  List<ReviewFlag>? reviewFlags,
});

final recordingDetailProvider = NotifierProvider.autoDispose
    .family<RecordingDetailNotifier, RecordingDetailState, String>(
      RecordingDetailNotifier.new,
    );

class RecordingDetailNotifier
    extends AutoDisposeFamilyNotifier<RecordingDetailState, String> {
  static final _log = Logger('RecordingDetailNotifier');
  bool _disposed = false;

  @override
  RecordingDetailState build(String arg) {
    // Riverpod 2.6.1 has no ref.mounted; flag dispose so post-await writes bail
    // instead of mutating a disposed (autoDispose) notifier.
    ref.onDispose(() => _disposed = true);

    // Mirror the screen's real-time DB stream: patch an already-loaded recording
    // when the row changes (native only). It does not seed the initial load.
    if (!kIsWeb) {
      ref.listen<AsyncValue<LocalRecordingEntity?>>(
        localRecordingStreamProvider(arg),
        (_, next) {
          final updated = next.valueOrNull;
          if (updated == null) return;
          final current = state.recording;
          if (current == null || identical(current, updated)) return;
          state = state.copyWith(recording: updated);
        },
      );
    }

    return const RecordingDetailState();
  }

  LocalRecordingRepository get _localRepo =>
      ref.read(localRecordingRepositoryProvider);
  RecordingApiRepository get _apiRepo =>
      ref.read(recordingApiRepositoryProvider);
  AudioCacheDownloader get _cacheDownloader =>
      ref.read(audioCacheDownloaderProvider);
  AudioExportDownloader get _exportDownloader =>
      ref.read(audioExportDownloaderProvider);
  RecordingFileImporter get _fileImporter =>
      ref.read(recordingFileImporterProvider);

  /// Resolves the recording (local → server-id fallback → metadata heal → API
  /// fallback), then resolves the storyteller and ensures the member cache is
  /// warm. Reproduces the screen's `_loadRecording` orchestration.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      LocalRecording? recording;
      var deletedOnServer = false;
      final isOnline = ref.read(syncNotifierProvider).isOnline;

      if (kIsWeb) {
        final server = await _apiRepo.getRecording(arg);
        if (_disposed) return;
        recording = serverRecordingToLocal(server);
      } else {
        recording = await _localRepo.getRecordingById(arg);
        if (_disposed) return;
        recording ??= await _localRepo.getRecordingByServerId(arg);
        if (_disposed) return;

        final current = recording;
        if (isOnline &&
            current != null &&
            _hasServerId(current) &&
            (_needsGcsRefresh(current) || _needsUserRefresh(current))) {
          final healed = await _healMetadata(current);
          if (healed == null) return;
          recording = healed.recording;
          deletedOnServer = healed.deletedOnServer;
        }

        if (isOnline && recording == null && !deletedOnServer) {
          try {
            final server = await _apiRepo.getRecording(arg);
            if (_disposed) return;
            recording = serverRecordingToLocal(server);
          } catch (_) {}
        }
      }

      final entity = recording == null
          ? null
          : localRecordingToEntity(recording);
      state = state.copyWith(
        recording: entity,
        clearRecording: entity == null,
        isLoading: false,
      );

      if (isOnline && entity != null) {
        await ref
            .read(roleNotifierProvider.notifier)
            .fetchRoleForProject(entity.projectId);
        if (_disposed) return;
        // Bump so the widget re-reads role-derived permissions (mirrors the
        // screen's empty setState after the role fetch).
        state = state.copyWith();
      }
      if (entity != null) {
        await _resolveStoryteller(entity);
        await _ensureMembersLoaded(entity.projectId);
      }
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refreshes [current] from the server when its stored metadata is
  /// incomplete, and reads a 404 as "the server hard-deleted it".
  ///
  /// Returns null when the notifier was disposed mid-flight, which is [load]'s
  /// signal to abandon the rest of the load. Otherwise returns the row to carry
  /// on with — the reloaded one, [current] itself when the refresh failed for
  /// any other reason, or null once the row has been erased. Requires a
  /// non-empty `serverId` ([_hasServerId]).
  Future<({LocalRecording? recording, bool deletedOnServer})?> _healMetadata(
    LocalRecording current,
  ) async {
    try {
      final server = await _apiRepo.getRecording(current.serverId!);
      if (_disposed) return null;
      final updates = buildHealMetadataCompanion(
        local: current,
        server: server,
      );
      await _localRepo.updateRecording(current.id, updates);
      if (_disposed) return null;
      final reloaded = await _localRepo.getRecordingById(current.id);
      if (_disposed) return null;
      return (recording: reloaded, deletedOnServer: false);
    } catch (e) {
      final erasable =
          isRecordingNotFound(e) &&
          serverHasRecording(
            serverId: current.serverId,
            uploadStatus: current.uploadStatus,
          );
      if (!erasable) return (recording: current, deletedOnServer: false);
      await _eraseDeletedOnServer(current);
      if (_disposed) return null;
      return (recording: null, deletedOnServer: true);
    }
  }

  /// The server hard-deleted this recording, so the local row and its audio are
  /// the leftovers of something that no longer exists anywhere.
  Future<void> _eraseDeletedOnServer(LocalRecording recording) async {
    await _localRepo.deleteRecording(recording.id);
    if (recording.localFilePath.isEmpty) return;
    try {
      await file_ops.deleteFile(recording.localFilePath);
    } on Exception catch (e, st) {
      // Best-effort: a missing/locked file must not abort the row delete.
      ref.read(errorReporterProvider).reportError(e, st);
    }
  }

  bool _hasServerId(LocalRecording r) =>
      r.serverId != null && r.serverId!.isNotEmpty;

  bool _needsGcsRefresh(LocalRecording r) =>
      (r.gcsUrl == null || r.gcsUrl!.isEmpty) &&
      const {'uploaded', 'verified'}.contains(r.uploadStatus);

  bool _needsUserRefresh(LocalRecording r) =>
      r.userId == null || r.userId!.isEmpty;

  Future<void> _resolveStoryteller(LocalRecordingEntity recording) async {
    final id = recording.storytellerId;
    if (id == null || id.isEmpty) {
      if (!_disposed) state = state.copyWith(clearStoryteller: true);
      return;
    }
    final localRepo = ref.read(
      storyteller_providers.localStorytellerRepositoryProvider,
    );
    final cached = await localRepo.getById(id);
    if (_disposed) return;
    if (cached != null) state = state.copyWith(resolvedStoryteller: cached);
    if (!ref.read(syncNotifierProvider).isOnline) return;
    try {
      final apiRepo = ref.read(
        storyteller_providers.storytellerApiRepositoryProvider,
      );
      final remote = await apiRepo.get(id);
      if (_disposed) return;
      state = state.copyWith(resolvedStoryteller: remote);
    } catch (_) {
      if (!_disposed && cached == null) {
        state = state.copyWith(clearStoryteller: true);
      }
    }
  }

  Future<void> _ensureMembersLoaded(String projectId) async {
    if (ref.read(memberNotifierProvider).members.isEmpty &&
        ref.read(syncNotifierProvider).isOnline) {
      await ref.read(memberNotifierProvider.notifier).fetchMembers(projectId);
      if (!_disposed) state = state.copyWith();
    }
  }

  /// Stores what the server said the recording still owes after a write it
  /// accepted (ENG-379).
  ///
  /// The pendency rule reads these off the local row for any recording the
  /// server knows about, and `load()` re-reads that row on native — so this has
  /// to land before the reload or the screen shows the state from before the
  /// edit. A null [flags] means the response said nothing about them and the
  /// stored answer stands.
  ///
  /// Best-effort by design: the edit itself already succeeded on the server, and
  /// failing to cache its flags must not undo that or be reported to the user as
  /// a failed save. Reported rather than swallowed (ENG-102).
  Future<void> _storeReviewFlags(String id, List<ReviewFlag>? flags) async {
    if (kIsWeb || flags == null || _disposed) return;
    try {
      await _localRepo.updateReviewFlags(id, flags);
    } catch (e, st) {
      if (_disposed) return;
      ref.read(errorReporterProvider).reportError(e, st);
    }
  }

  Future<void> setStoryteller(
    LocalRecordingEntity recording,
    Storyteller? storyteller,
  ) async {
    final serverId = recording.serverId ?? recording.id;
    UpdateRecordingOutcome? outcome;
    try {
      outcome = await _apiRepo.updateRecording(
        serverId,
        UpdateRecordingRequest(storytellerId: storyteller?.id ?? ''),
      );
    } on Exception catch (_) {}
    if (_disposed) return;
    if (!kIsWeb) {
      await _localRepo.setStoryteller(
        recording.id,
        storytellerId: storyteller?.id,
      );
      if (_disposed) return;
      await _storeReviewFlags(recording.id, outcome?.reviewFlags);
      if (_disposed) return;
    }
    await load();
  }

  /// Saves an edited title and/or description. Title routes through the existing
  /// [saveRecordingTitle] use-case; description through the typed repo write.
  Future<RecordingMutationResult> saveDetails(
    LocalRecordingEntity recording, {
    required String title,
    required String description,
  }) async {
    final isOnline = ref.read(syncNotifierProvider).isOnline;
    final localRepo = kIsWeb ? null : _localRepo;

    final titleChanged = title != (recording.title ?? '').trim();
    final descriptionChanged =
        description != (recording.description ?? '').trim();

    // The ENG-380 use-cases already tell a local-only save apart from one the
    // server took; either half being local-only makes the whole edit pending.
    var localOnly = false;
    RecordingMutationResult saved() => localOnly
        ? RecordingMutationResult.savedLocallyOnly
        : RecordingMutationResult.success;

    if (titleChanged) {
      try {
        final titleResult = await saveRecordingTitle(
          recordingId: arg,
          currentTitle: recording.title,
          serverId: recording.serverId,
          newTitle: title,
          isWeb: kIsWeb,
          isOnline: isOnline,
          apiRepo: _apiRepo,
          localRepo: localRepo,
        );
        localOnly = titleResult == SaveTitleResult.savedLocallyOnly;
        if (_disposed) return saved();
        if (titleResult == SaveTitleResult.saved ||
            titleResult == SaveTitleResult.savedLocallyOnly) {
          // The use-case reports `saved` both for a write the server took and
          // for one that never needed it (no server copy). Settling either way
          // is right: the second is a no-op on a row that owes nothing, and it
          // is what clears a title owed from an earlier offline rename.
          await _settleOutbox(arg, const {
            PendingMetadataField.title,
          }, owed: localOnly);
          if (_disposed) return saved();
          ref
              .read(recordingsListNotifierProvider.notifier)
              .patchRecordingTitle(arg, title);
          // A row parked in failed_conflict is terminal until the clashing
          // title changes; the rename is what makes it uploadable again, so
          // hand it straight back to the queue instead of leaving it stuck.
          if (recording.uploadStatus == 'failed_conflict') {
            await ref
                .read(syncNotifierProvider.notifier)
                .resetAndRetry(recording.id);
            if (_disposed) return saved();
          }
        }
      } on ForbiddenException {
        return RecordingMutationResult.forbidden;
      } on ConflictException {
        // The new title is taken too. Nothing was written locally, so the row
        // keeps its old title and its failed_conflict status — the banner stays
        // and the user can pick another name.
        return RecordingMutationResult.titleConflict;
      }
    }

    if (descriptionChanged) {
      try {
        final descriptionResult = await saveRecordingDescription(
          recordingId: arg,
          serverId: recording.serverId,
          description: description,
          isWeb: kIsWeb,
          isOnline: ref.read(syncNotifierProvider).isOnline,
          apiRepo: _apiRepo,
          localRepo: localRepo,
        );
        final descriptionLocalOnly =
            descriptionResult == SaveDescriptionResult.savedLocallyOnly;
        localOnly = localOnly || descriptionLocalOnly;
        if (_disposed) return saved();
        await _settleOutbox(arg, const {
          PendingMetadataField.description,
        }, owed: descriptionLocalOnly);
        if (_disposed) return saved();
      } on ForbiddenException {
        return RecordingMutationResult.forbidden;
      }
      // A row parked in failed_description is terminal until the description
      // grows; the edit is what makes it uploadable again, so hand it straight
      // back to the queue instead of leaving it stuck.
      if (recording.uploadStatus == 'failed_description') {
        await ref
            .read(syncNotifierProvider.notifier)
            .resetAndRetry(recording.id);
        if (_disposed) return saved();
      }
    }

    if (titleChanged || descriptionChanged) {
      await load();
    }
    return saved();
  }

  /// Sends a metadata write to the server, classifying the outcome instead of
  /// collapsing every failure into one (ENG-399).
  ///
  /// A refusal (403, or a response that says it did not take) is a real error
  /// and the caller must not write locally. Not reaching the server — offline,
  /// or a request that never came back — is not: the caller mirrors the edit to
  /// the local row and tells the user it stopped there. Web has no local row,
  /// so there is nothing to fall back to and an unreachable server is simply a
  /// failure.
  Future<_ServerWriteOutcome> _pushMetadata(
    String serverId,
    UpdateRecordingRequest request,
  ) async {
    if (!kIsWeb && !ref.read(syncNotifierProvider).isOnline) {
      return (status: _ServerWrite.unreachable, reviewFlags: null);
    }
    try {
      final outcome = await _apiRepo.updateRecording(serverId, request);
      return (
        status: outcome.success ? _ServerWrite.accepted : _ServerWrite.rejected,
        reviewFlags: outcome.reviewFlags,
      );
    } on ForbiddenException {
      return (status: _ServerWrite.forbidden, reviewFlags: null);
    } catch (_) {
      return (
        status: kIsWeb ? _ServerWrite.rejected : _ServerWrite.unreachable,
        reviewFlags: null,
      );
    }
  }

  /// Records that the server is still owed [fields], or drops them once it has
  /// taken them (ENG-403).
  ///
  /// Only the *names* are stored. The local row already holds the edited value
  /// — every caller below writes it there first — so the drain reads the value
  /// back off the row when it finally reaches the server. That is what makes
  /// two offline edits to one field collapse into a single write instead of a
  /// replay, and what keeps a field this device never touched out of the PATCH.
  ///
  /// Callers must only reach here when the recording actually has a server copy
  /// to owe; without one the metadata rides along on the upload's create call
  /// and a pendency would never be drainable.
  Future<void> _settleOutbox(
    String id,
    Set<PendingMetadataField> fields, {
    required bool owed,
  }) async {
    if (kIsWeb || _disposed) return;
    if (owed) {
      await _localRepo.markMetadataPending(id, fields);
    } else {
      await _localRepo.clearPendingMetadataFields(id, fields);
    }
  }

  /// Maps a server refusal to the result the widget reports, or null when the
  /// caller should carry on and write the local row.
  RecordingMutationResult? _refusal(_ServerWrite status) => switch (status) {
    _ServerWrite.forbidden => RecordingMutationResult.forbidden,
    _ServerWrite.rejected => RecordingMutationResult.failed,
    _ServerWrite.accepted || _ServerWrite.unreachable => null,
  };

  Future<RecordingMutationResult> toggleCleaningStatus(
    LocalRecordingEntity recording,
  ) async {
    final newStatus = recording.cleaningStatus == 'none'
        ? 'needs_cleaning'
        : 'none';

    // `serverId`, not `uploadStatus` — the same gate the other four mutations
    // use. The two agreed only because `markAsUploaded` writes the status and
    // the id in one statement, an undocumented invariant the outbox would have
    // made load-bearing: were it ever to break, this would mark a pendency that
    // `getPendingMetadataSyncs` (which requires a `serverId`) never selects,
    // and the row would read as pending forever. It also closes a gap of its
    // own — a row that has a `serverId` but is not yet `uploaded` skips the
    // create on retry, so a cleaning status written only locally would never
    // reach the server at all.
    final hasServerId =
        recording.serverId != null && recording.serverId!.isNotEmpty;

    var localOnly = false;
    if (kIsWeb || hasServerId) {
      final write = await _pushMetadata(
        recording.serverId ?? recording.id,
        UpdateRecordingRequest(cleaningStatus: newStatus),
      );
      final refusal = _refusal(write.status);
      if (refusal != null) return refusal;
      if (_disposed) return RecordingMutationResult.success;
      localOnly = write.status == _ServerWrite.unreachable;
    }
    final saved = localOnly
        ? RecordingMutationResult.savedLocallyOnly
        : RecordingMutationResult.success;

    if (!kIsWeb) {
      await _localRepo.updateCleaningStatus(arg, newStatus);
      if (_disposed) return saved;
      if (hasServerId) {
        await _settleOutbox(arg, const {
          PendingMetadataField.cleaningStatus,
        }, owed: localOnly);
        if (_disposed) return saved;
      }
    }
    await load();
    return saved;
  }

  Future<RecordingMutationResult> moveCategory(
    LocalRecordingEntity recording,
    MoveCategoryResult result,
  ) async {
    final write = await _pushMetadata(
      recording.serverId ?? recording.id,
      UpdateRecordingRequest(
        genreId: result.genreId,
        subcategoryId: result.subcategoryId,
        secondaryGenreId: result.secondaryGenreId,
        secondarySubcategoryId: result.secondarySubcategoryId,
        secondaryRegisterId: result.secondaryRegisterId,
        clearSecondary: result.clearSecondary,
      ),
    );
    final refusal = _refusal(write.status);
    if (refusal != null) return refusal;
    if (_disposed) return RecordingMutationResult.success;

    final serverFlags = write.reviewFlags;
    final localOnly = write.status == _ServerWrite.unreachable;
    final saved = localOnly
        ? RecordingMutationResult.savedLocallyOnly
        : RecordingMutationResult.success;

    if (!kIsWeb) {
      await _localRepo.moveCategory(
        recording.id,
        genreId: result.genreId,
        subcategoryId: result.subcategoryId,
        clearSecondary: result.clearSecondary,
        secondaryGenreId: result.secondaryGenreId,
        secondarySubcategoryId: result.secondarySubcategoryId,
        secondaryRegisterId: result.secondaryRegisterId,
      );
      if (_disposed) return saved;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return saved;
      // Unlike the other mutations this one pushes without checking for a
      // server copy, so the "unreachable" it reports for a recording the server
      // never had is not something the drain could ever settle.
      if (recording.serverId != null && recording.serverId!.isNotEmpty) {
        await _settleOutbox(recording.id, const {
          PendingMetadataField.genre,
          PendingMetadataField.subcategory,
          PendingMetadataField.secondary,
        }, owed: localOnly);
        if (_disposed) return saved;
      }
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      unawaited(
        ref
            .read(statsNotifierProvider.notifier)
            .fetchGenreStats(recording.projectId),
      );
    }
    await load();
    return saved;
  }

  Future<RecordingMutationResult> classify(
    LocalRecordingEntity recording,
    ClassifyResult result,
  ) async {
    final hasServerId =
        recording.serverId != null && recording.serverId!.isNotEmpty;

    final clearSecondary =
        result.secondaryGenreId == null &&
        result.secondaryRegisterId == null &&
        (recording.secondaryGenreId != null ||
            recording.secondaryRegisterId != null);

    // The gate stays `hasServerId`, not uploadStatus: a recording the server
    // has never seen owes it nothing, so skipping the call is not a fallback
    // and must not be reported as a pending edit.
    List<ReviewFlag>? serverFlags;
    var localOnly = false;
    if (hasServerId) {
      final write = await _pushMetadata(
        recording.serverId!,
        UpdateRecordingRequest(
          genreId: result.genreId,
          subcategoryId: result.subcategoryId,
          registerId: result.registerId,
          secondaryGenreId: result.secondaryGenreId,
          secondarySubcategoryId: result.secondarySubcategoryId,
          secondaryRegisterId: result.secondaryRegisterId,
          clearSecondary: clearSecondary,
        ),
      );
      final refusal = _refusal(write.status);
      if (refusal != null) return refusal;
      if (_disposed) return RecordingMutationResult.success;
      serverFlags = write.reviewFlags;
      localOnly = write.status == _ServerWrite.unreachable;
    }
    final saved = localOnly
        ? RecordingMutationResult.savedLocallyOnly
        : RecordingMutationResult.success;

    if (!kIsWeb) {
      await _localRepo.classify(
        recording.id,
        genreId: result.genreId,
        subcategoryId: result.subcategoryId,
        registerId: result.registerId,
        secondaryGenreId: result.secondaryGenreId,
        secondarySubcategoryId: result.secondarySubcategoryId,
        secondaryRegisterId: result.secondaryRegisterId,
      );
      if (_disposed) return saved;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return saved;
      if (hasServerId) {
        await _settleOutbox(recording.id, const {
          PendingMetadataField.genre,
          PendingMetadataField.subcategory,
          PendingMetadataField.register,
          PendingMetadataField.secondary,
        }, owed: localOnly);
        if (_disposed) return saved;
      }

      if (!hasServerId && ref.read(syncNotifierProvider).isOnline) {
        unawaited(ref.read(syncNotifierProvider.notifier).processQueue());
      }
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      unawaited(
        ref
            .read(statsNotifierProvider.notifier)
            .fetchGenreStats(recording.projectId),
      );
    }
    await load();
    return saved;
  }

  /// Persists (or clears, when [values] is null) the secondary classification.
  Future<RecordingMutationResult> saveSecondary(
    LocalRecordingEntity recording,
    SecondaryValues? values,
  ) async {
    final hasServerId =
        recording.serverId != null && recording.serverId!.isNotEmpty;
    final clearSecondary = values == null;

    List<ReviewFlag>? serverFlags;
    var localOnly = false;
    if (hasServerId) {
      final write = await _pushMetadata(
        recording.serverId!,
        UpdateRecordingRequest(
          secondaryGenreId: values?.genreId,
          secondarySubcategoryId: values?.subcategoryId,
          secondaryRegisterId: values?.registerId,
          clearSecondary: clearSecondary,
        ),
      );
      final refusal = _refusal(write.status);
      if (refusal != null) return refusal;
      if (_disposed) return RecordingMutationResult.success;
      serverFlags = write.reviewFlags;
      localOnly = write.status == _ServerWrite.unreachable;
    }
    final saved = localOnly
        ? RecordingMutationResult.savedLocallyOnly
        : RecordingMutationResult.success;

    if (!kIsWeb) {
      await _localRepo.updateSecondaryClassification(
        recording.id,
        genreId: values?.genreId,
        subcategoryId: values?.subcategoryId,
        registerId: values?.registerId,
      );
      if (_disposed) return saved;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return saved;
      if (hasServerId) {
        await _settleOutbox(recording.id, const {
          PendingMetadataField.secondary,
        }, owed: localOnly);
        if (_disposed) return saved;
      }
    }

    await load();
    return saved;
  }

  /// Downloads the recording's audio from GCS and caches it locally, then
  /// reloads. Throws on download failure so the widget can surface the error
  /// (and dismiss its progress dialog) exactly as the screen did inline.
  Future<void> downloadAndCache(LocalRecordingEntity recording) async {
    final path = await _cacheDownloader(
      url: recording.gcsUrl!,
      format: recording.format,
    );
    if (_disposed) return;
    await _localRepo.cacheDownloadedAudio(
      recording: recording,
      localFilePath: path,
    );
    if (_disposed) return;
    await load();
  }

  /// Downloads the audio to a temp file for sharing (web export). Throws on
  /// download failure.
  Future<String> downloadForExport(LocalRecordingEntity recording) {
    return _exportDownloader(
      url: recording.gcsUrl!,
      recordingId: recording.id,
      format: recording.format,
    );
  }

  /// Replaces the recording's audio with a picked file: imports the file (copy +
  /// trash old + invalidate waveform), updates the row, syncs new metadata to
  /// the server when the recording was uploaded, then reloads. Returns false on
  /// failure (the screen showed `recording_replaceFailed`).
  Future<bool> replaceAudio(
    LocalRecordingEntity recording, {
    required String sourcePath,
    required String fileName,
    required double durationSeconds,
  }) async {
    final wasUploaded =
        recording.uploadStatus == 'uploaded' ||
        recording.uploadStatus == 'verified';
    final sync = ref.read(syncNotifierProvider.notifier);
    try {
      final imported = await _fileImporter(
        sourcePath: sourcePath,
        fileName: fileName,
        oldPath: recording.localFilePath,
        recordingId: recording.id,
        format: recording.format,
      );
      if (_disposed) return true;
      await _localRepo.replaceAudio(
        recordingId: recording.id,
        newFilePath: imported.path,
        newDurationSeconds: durationSeconds,
        newFileSizeBytes: imported.sizeBytes,
      );
      if (_disposed) return true;

      if (wasUploaded) {
        final serverId = recording.serverId ?? recording.id;
        try {
          await _apiRepo.updateRecording(
            serverId,
            UpdateRecordingRequest(
              durationSeconds: durationSeconds,
              fileSizeBytes: imported.sizeBytes,
            ),
          );
        } on Exception catch (e) {
          _log.warning('replace: failed to sync new metadata to server', e);
        }
        if (_disposed) return true;
        await sync.resetAndRetry(recording.id);
        if (_disposed) return true;
      }

      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
