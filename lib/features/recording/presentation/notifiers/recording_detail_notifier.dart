import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/app_exception.dart' show ConflictException;
import '../../../../core/observability/error_reporter.dart';
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
import '../../data/use_cases/save_recording_title.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../../domain/entities/review_flag.dart';
import '../../domain/entities/update_recording_request.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../widgets/classify_recording_dialog.dart' show ClassifyResult;
import '../widgets/move_category_dialog.dart' show MoveCategoryResult;
import '../widgets/secondary_classification_fields.dart' show SecondaryValues;
import 'recording_detail_state.dart';
import 'recordings_list_notifier.dart';

/// Outcome the headless notifier hands back to the widget for the metadata
/// mutations (move/classify/secondary/cleaning/edit). The notifier has no
/// BuildContext, so the widget maps each result to its own localized snackbar.
enum RecordingMutationResult { success, failed, forbidden, titleConflict }

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
          try {
            final server = await _apiRepo.getRecording(current.serverId!);
            if (_disposed) return;
            final updates = buildHealMetadataCompanion(
              local: current,
              server: server,
            );
            await _localRepo.updateRecording(current.id, updates);
            if (_disposed) return;
            recording = await _localRepo.getRecordingById(current.id);
            if (_disposed) return;
          } catch (_) {}
        }

        if (isOnline && recording == null) {
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
        if (_disposed) return RecordingMutationResult.success;
        if (titleResult == SaveTitleResult.saved ||
            titleResult == SaveTitleResult.savedLocallyOnly) {
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
            if (_disposed) return RecordingMutationResult.success;
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
        if (kIsWeb) {
          final serverId = recording.serverId ?? arg;
          await _apiRepo.updateRecording(
            serverId,
            UpdateRecordingRequest(description: description),
          );
        } else {
          await localRepo!.updateDescription(arg, description);
        }
        if (_disposed) return RecordingMutationResult.success;
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
        if (_disposed) return RecordingMutationResult.success;
      }
    }

    if (titleChanged || descriptionChanged) {
      await load();
    }
    return RecordingMutationResult.success;
  }

  Future<RecordingMutationResult> toggleCleaningStatus(
    LocalRecordingEntity recording,
  ) async {
    final newStatus = recording.cleaningStatus == 'none'
        ? 'needs_cleaning'
        : 'none';
    final serverId = recording.serverId ?? recording.id;

    if (recording.uploadStatus == 'uploaded' || kIsWeb) {
      try {
        final outcome = await _apiRepo.updateRecording(
          serverId,
          UpdateRecordingRequest(cleaningStatus: newStatus),
        );
        if (_disposed) return RecordingMutationResult.success;
        if (!outcome.success) return RecordingMutationResult.failed;
      } on ForbiddenException {
        return RecordingMutationResult.forbidden;
      } catch (_) {
        return RecordingMutationResult.failed;
      }
    }

    if (!kIsWeb) {
      await _localRepo.updateCleaningStatus(arg, newStatus);
      if (_disposed) return RecordingMutationResult.success;
    }
    await load();
    return RecordingMutationResult.success;
  }

  Future<RecordingMutationResult> moveCategory(
    LocalRecordingEntity recording,
    MoveCategoryResult result,
  ) async {
    final serverId = recording.serverId ?? recording.id;
    List<ReviewFlag>? serverFlags;
    try {
      final outcome = await _apiRepo.updateRecording(
        serverId,
        UpdateRecordingRequest(
          genreId: result.genreId,
          subcategoryId: result.subcategoryId,
          secondaryGenreId: result.secondaryGenreId,
          secondarySubcategoryId: result.secondarySubcategoryId,
          secondaryRegisterId: result.secondaryRegisterId,
          clearSecondary: result.clearSecondary,
        ),
      );
      if (_disposed) return RecordingMutationResult.success;
      if (!outcome.success) return RecordingMutationResult.failed;
      serverFlags = outcome.reviewFlags;
    } on ForbiddenException {
      return RecordingMutationResult.forbidden;
    } catch (_) {
      return RecordingMutationResult.failed;
    }

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
      if (_disposed) return RecordingMutationResult.success;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return RecordingMutationResult.success;
    }

    if (ref.read(syncNotifierProvider).isOnline) {
      unawaited(
        ref
            .read(statsNotifierProvider.notifier)
            .fetchGenreStats(recording.projectId),
      );
    }
    await load();
    return RecordingMutationResult.success;
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

    List<ReviewFlag>? serverFlags;
    if (hasServerId) {
      try {
        final outcome = await _apiRepo.updateRecording(
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
        if (_disposed) return RecordingMutationResult.success;
        if (!outcome.success) return RecordingMutationResult.failed;
        serverFlags = outcome.reviewFlags;
      } on ForbiddenException {
        return RecordingMutationResult.forbidden;
      } catch (_) {
        return RecordingMutationResult.failed;
      }
    }

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
      if (_disposed) return RecordingMutationResult.success;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return RecordingMutationResult.success;

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
    return RecordingMutationResult.success;
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
    if (hasServerId) {
      try {
        final outcome = await _apiRepo.updateRecording(
          recording.serverId!,
          UpdateRecordingRequest(
            secondaryGenreId: values?.genreId,
            secondarySubcategoryId: values?.subcategoryId,
            secondaryRegisterId: values?.registerId,
            clearSecondary: clearSecondary,
          ),
        );
        if (_disposed) return RecordingMutationResult.success;
        if (!outcome.success) return RecordingMutationResult.failed;
        serverFlags = outcome.reviewFlags;
      } on ForbiddenException {
        return RecordingMutationResult.forbidden;
      } catch (_) {
        return RecordingMutationResult.failed;
      }
    }

    if (!kIsWeb) {
      await _localRepo.updateSecondaryClassification(
        recording.id,
        genreId: values?.genreId,
        subcategoryId: values?.subcategoryId,
        registerId: values?.registerId,
      );
      if (_disposed) return RecordingMutationResult.success;
      await _storeReviewFlags(recording.id, serverFlags);
      if (_disposed) return RecordingMutationResult.success;
    }

    await load();
    return RecordingMutationResult.success;
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
