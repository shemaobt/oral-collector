import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/utils/recording_title.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../data/server_to_local_recording.dart';
import '../../data/services/local_segment_exporter.dart';
import '../../data/services/recording_split_persister.dart';
import '../../data/services/recording_trash.dart';
import '../../domain/entities/split_segment_request.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../trim_edit_decision.dart';
import '../trim_load_error.dart';
import 'trim_editor_state.dart';

/// What a [TrimEditorNotifier.saveSplit] resolved to. The notifier is headless
/// (no BuildContext), so it returns the data the widget needs to show the right
/// snackbar and navigate, instead of doing it itself.
sealed class TrimSaveOutcome {
  const TrimSaveOutcome();
}

class TrimSaveSucceeded extends TrimSaveOutcome {
  const TrimSaveSucceeded({
    required this.mode,
    required this.keptCount,
    required this.excludedCount,
  });

  final TrimSaveMode mode;
  final int keptCount;
  final int excludedCount;
}

class TrimSaveAborted extends TrimSaveOutcome {
  const TrimSaveAborted();
}

class TrimSaveFailed extends TrimSaveOutcome {
  const TrimSaveFailed(this.error);
  final Object error;
}

final trimEditorProvider = NotifierProvider.autoDispose
    .family<TrimEditorNotifier, TrimEditorState, String>(
      TrimEditorNotifier.new,
    );

class TrimEditorNotifier
    extends AutoDisposeFamilyNotifier<TrimEditorState, String> {
  bool _disposed = false;

  @override
  TrimEditorState build(String arg) {
    // Riverpod 2.6.1 has no ref.mounted; flag dispose so post-await writes bail
    // instead of mutating a disposed (autoDispose) notifier.
    ref.onDispose(() => _disposed = true);
    return const TrimEditorState();
  }

  LocalRecordingRepository get _localRepo =>
      ref.read(localRecordingRepositoryProvider);
  RecordingApiRepository get _apiRepo =>
      ref.read(recordingApiRepositoryProvider);
  LocalSegmentExporter get _exporter => ref.read(localSegmentExporterProvider);
  RecordingSplitPersisterFactory get _persisterFactory =>
      ref.read(recordingSplitPersisterProvider);

  /// Resolves the recording row only. The widget owns the player, the file-
  /// availability check and the waveform/duration, finishing the load via
  /// [setUnavailable] or [completeLoad] (which is why a resolved recording
  /// keeps `isLoading` true here).
  Future<void> load({required bool isWeb}) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearLoadError: true,
    );

    LocalRecording? recording;
    if (isWeb) {
      try {
        final server = await _apiRepo.getRecording(arg);
        if (_disposed) return;
        recording = serverRecordingToLocal(server);
      } catch (e) {
        if (_disposed) return;
        if (_handleServerLoadError(e)) return;
      }
    } else {
      recording = await _localRepo.getRecordingById(arg);
      if (_disposed) return;
      recording ??= await _localRepo.getRecordingByServerId(arg);
      if (_disposed) return;
      if (recording == null) {
        try {
          final server = await _apiRepo.getRecording(arg);
          if (_disposed) return;
          recording = serverRecordingToLocal(server);
        } catch (e) {
          if (_disposed) return;
          if (_handleServerLoadError(e)) return;
        }
      }
    }

    if (recording == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(recording: recording);
  }

  /// A caught load error is "not found" only for a genuine 404; everything else
  /// surfaces as a real error (ENG-140 F21). Returns true when the caller should
  /// stop (error stored); false for a 404 so it falls through to not-found.
  bool _handleServerLoadError(Object e) {
    if (isRecordingNotFound(e)) return false;
    state = state.copyWith(isLoading: false, loadError: e);
    return true;
  }

  /// The widget's player/availability check found the audio missing.
  void setUnavailable(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  /// The widget finished wiring the player and resolved the total duration.
  void completeLoad({required Duration totalDuration}) {
    state = state.copyWith(totalDuration: totalDuration, isLoading: false);
  }

  void setSplitPoints(List<double> points) {
    final newSegCount = points.length + 1;
    final pruned = state.excludedSegments
        .where((i) => i < newSegCount)
        .toSet();
    final previousBoundaries = state.boundaries;
    final newBoundaries = [0.0, ...[...points]..sort(), 1.0];
    state = state.copyWith(
      splitPoints: points,
      excludedSegments: pruned,
      segGenreBySig: remapTaxonomyBySig(
        state.segGenreBySig,
        previousBoundaries,
        newBoundaries,
      ),
      segSubcatBySig: remapTaxonomyBySig(
        state.segSubcatBySig,
        previousBoundaries,
        newBoundaries,
      ),
      segRegisterBySig: remapTaxonomyBySig(
        state.segRegisterBySig,
        previousBoundaries,
        newBoundaries,
      ),
    );
  }

  /// Returns false when the "at least one segment" guard blocks the exclusion
  /// (the widget surfaces the snackbar); state is mutated only when it returns
  /// true.
  bool toggleExclude(int index) {
    final updated = Set<int>.from(state.excludedSegments);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      if (updated.length >= state.segmentCount - 1) return false;
      updated.add(index);
    }
    state = state.copyWith(excludedSegments: updated);
    return true;
  }

  void setSegmentTaxonomy({
    required int index,
    required bool applyToAll,
    required String? genreId,
    required String? subcategoryId,
    required String? registerId,
  }) {
    if (applyToAll) {
      state = state.copyWith(
        segGenreBySig: {
          for (var i = 0; i < state.segmentCount; i++)
            state.sigForSegment(i): genreId,
        },
        segSubcatBySig: {
          for (var i = 0; i < state.segmentCount; i++)
            state.sigForSegment(i): subcategoryId,
        },
        segRegisterBySig: {
          for (var i = 0; i < state.segmentCount; i++)
            state.sigForSegment(i): registerId,
        },
      );
    } else {
      final sig = state.sigForSegment(index);
      state = state.copyWith(
        segGenreBySig: {...state.segGenreBySig, sig: genreId},
        segSubcatBySig: {...state.segSubcatBySig, sig: subcategoryId},
        segRegisterBySig: {...state.segRegisterBySig, sig: registerId},
      );
    }
  }

  void copyFromPrevious(int index) {
    if (index <= 0) return;
    final previousSig = state.sigForSegment(index - 1);
    final currentSig = state.sigForSegment(index);

    final prevGenre = state.segGenreBySig.containsKey(previousSig)
        ? state.segGenreBySig[previousSig]
        : null;
    final prevSub = state.segSubcatBySig.containsKey(previousSig)
        ? state.segSubcatBySig[previousSig]
        : state.recording?.subcategoryId;
    final prevReg = state.segRegisterBySig.containsKey(previousSig)
        ? state.segRegisterBySig[previousSig]
        : state.recording?.registerId;

    state = state.copyWith(
      segGenreBySig: {...state.segGenreBySig, currentSig: prevGenre},
      segSubcatBySig: {...state.segSubcatBySig, currentSig: prevSub},
      segRegisterBySig: {...state.segRegisterBySig, currentSig: prevReg},
    );
  }

  void setGain(double gainDb) {
    state = state.copyWith(gainDb: gainDb);
  }

  void clearAllSplits() {
    state = state.copyWith(splitPoints: const [], excludedSegments: const {});
  }

  void restoreAllExcluded() {
    state = state.copyWith(excludedSegments: const {});
  }

  Future<TrimSaveOutcome> saveSplit({
    required bool isWeb,
    required String localeTag,
  }) async {
    final recording = state.recording;
    if (recording == null) return const TrimSaveAborted();
    if (!state.decision.canSave) return const TrimSaveAborted();

    final mode = state.decision.mode;
    final keptCount = state.keptSegmentIndices.length;
    final excludedCount = state.excludedSegments.length;

    state = state.copyWith(isSaving: true);
    try {
      if (isWeb) {
        await _saveServerSide(recording);
      } else {
        await _saveLocally(recording, localeTag);
      }
      return TrimSaveSucceeded(
        mode: mode,
        keptCount: keptCount,
        excludedCount: excludedCount,
      );
    } on Object catch (e) {
      if (!_disposed) state = state.copyWith(isSaving: false);
      return TrimSaveFailed(e);
    }
  }

  Future<void> _saveServerSide(LocalRecording recording) async {
    final apiRepo = _apiRepo;
    final serverId = recording.serverId ?? recording.id;
    final kept = state.keptSegmentIndices;
    final hasGain = state.gainDb.abs() > 0.01;

    final segments = kept.map((i) {
      final effGenre = state.effectiveGenre(i);
      final effSubcat = state.effectiveSubcategory(i);
      final effRegister = state.effectiveRegister(i);
      return SplitSegmentRequest(
        startSeconds: state.segmentStart(i).inMilliseconds / 1000.0,
        endSeconds: state.segmentEnd(i).inMilliseconds / 1000.0,
        genreId: effGenre.isNotEmpty ? effGenre : null,
        subcategoryId: (effSubcat != null && effSubcat.isNotEmpty)
            ? effSubcat
            : null,
        registerId: (effRegister != null && effRegister.isNotEmpty)
            ? effRegister
            : null,
        gainDb: hasGain ? state.gainDb : null,
      );
    }).toList();

    await apiRepo.splitRecording(serverId: serverId, segments: segments);
  }

  Future<void> _saveLocally(LocalRecording recording, String localeTag) async {
    // Capture every dependency before the first await: the notifier is
    // autoDispose, so reading ref after a suspension could throw, yet the split
    // must still commit even if the user navigates away mid-export.
    final exporter = _exporter;
    final persisterFactory = _persisterFactory;
    final localRepo = _localRepo;
    final apiRepo = _apiRepo;
    final triggerUpload = ref.read(syncNotifierProvider.notifier).processQueue;

    final originalTitle =
        recording.title ?? defaultRecordingTitle(locale: localeTag);
    final kept = state.keptSegmentIndices;
    final boostOnly = state.decision.mode == TrimSaveMode.boostOnly;

    final exportSegments = [
      for (final i in kept)
        SegmentExportSpec(
          startSeconds: state.segmentStart(i).inMilliseconds / 1000.0,
          endSeconds: state.segmentEnd(i).inMilliseconds / 1000.0,
          genreOverride: state.effectiveGenre(i),
          subcategoryOverride: state.effectiveSubcategory(i),
          registerOverride: state.effectiveRegister(i),
        ),
    ];

    final specs = await exporter(
      sourceFilePath: recording.localFilePath,
      segments: exportSegments,
      gainDb: state.gainDb,
      boostOnly: boostOnly,
      originalTitle: originalTitle,
      parentGenreId: recording.genreId,
    );

    final persister = persisterFactory(
      localRepo: localRepo,
      apiRepo: apiRepo,
      triggerUpload: triggerUpload,
      trashParent: (parent) => RecordingTrash.putInTrash(
        sourcePath: parent.localFilePath,
        metadata: {
          'id': parent.id,
          'title': parent.title,
          'description': parent.description,
          'projectId': parent.projectId,
          'genreId': parent.genreId,
          'subcategoryId': parent.subcategoryId,
          'registerId': parent.registerId,
          'secondaryGenreId': parent.secondaryGenreId,
          'secondarySubcategoryId': parent.secondarySubcategoryId,
          'secondaryRegisterId': parent.secondaryRegisterId,
          'storytellerId': parent.storytellerId,
          'userId': parent.userId,
          'durationSeconds': parent.durationSeconds,
          'fileSizeBytes': parent.fileSizeBytes,
          'format': parent.format,
          'serverId': parent.serverId,
          'gcsUrl': parent.gcsUrl,
          'recordedAt': parent.recordedAt.toIso8601String(),
        },
      ),
    );
    await persister.persist(parent: recording, segments: specs);
  }
}
