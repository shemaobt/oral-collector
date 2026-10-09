import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../shared/utils/recording_title.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../data/server_to_recording_entity.dart';
import '../../data/services/joined_audio_exporter.dart';
import '../../data/services/local_segment_exporter.dart';
import '../../data/services/recording_boost_persister.dart';
import '../../data/services/recording_save_as_new_persister.dart';
import '../../data/services/recording_split_persister.dart';
import '../../data/services/recording_trash.dart';
import '../../domain/audible_gain.dart';
import '../../domain/entities/local_recording_entity.dart';
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
  static final _log = Logger('TrimEditorNotifier');
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
  RecordingBoostPersisterFactory get _boostPersisterFactory =>
      ref.read(recordingBoostPersisterProvider);
  JoinedAudioExporter get _joiner => ref.read(joinedAudioExporterProvider);

  /// Resolves the recording only. The widget owns the player, the file-
  /// availability check and the waveform/duration, finishing the load via
  /// [setUnavailable] or [completeLoad] (which is why a resolved recording
  /// keeps `isLoading` true here).
  Future<void> load({required bool isWeb}) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearLoadError: true,
    );

    LocalRecordingEntity? recording;
    if (isWeb) {
      try {
        final server = await _apiRepo.getRecording(arg);
        if (_disposed) return;
        recording = serverRecordingToEntity(server);
      } catch (e, st) {
        if (_disposed) return;
        if (_handleServerLoadError(e, st)) return;
      }
    } else {
      recording = await _localRepo.getRecordingEntityById(arg);
      if (_disposed) return;
      recording ??= await _localRepo.getRecordingEntityByServerId(arg);
      if (_disposed) return;
      if (recording == null) {
        try {
          final server = await _apiRepo.getRecording(arg);
          if (_disposed) return;
          recording = serverRecordingToEntity(server);
        } catch (e, st) {
          if (_disposed) return;
          if (_handleServerLoadError(e, st)) return;
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
  bool _handleServerLoadError(Object e, StackTrace st) {
    _log.warning('server lookup failed for $arg', e, st);
    if (isRecordingNotFound(e)) return false;
    state = state.copyWith(isLoading: false, loadError: e);
    return true;
  }

  /// The widget's player/availability check found the audio missing.
  void setUnavailable(String message) {
    if (_disposed) return;
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  /// The widget finished wiring the player and resolved the total duration.
  void completeLoad({required Duration totalDuration}) {
    if (_disposed) return;
    state = state.copyWith(totalDuration: totalDuration, isLoading: false);
  }

  /// Player/waveform setup threw after the row resolved; drop back to the
  /// not-found state, matching the screen's original outer-catch behaviour
  /// (the recording was only committed on a fully successful load).
  void loadFailed() {
    if (_disposed) return;
    state = state.copyWith(clearRecording: true, isLoading: false);
  }

  void setSplitPoints(List<double> points) {
    final newSegCount = points.length + 1;
    final pruned = state.excludedSegments.where((i) => i < newSegCount).toSet();
    final previousBoundaries = state.boundaries;
    final newBoundaries = [
      0.0,
      ...[...points]..sort(),
      1.0,
    ];
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
    TrimSaveMode? mode,
  }) async {
    final recording = state.recording;
    if (recording == null) return const TrimSaveAborted();
    if (!state.decision.canSave) return const TrimSaveAborted();

    final saveMode = isWeb ? state.decision.mode : mode ?? state.decision.mode;
    final keptCount = state.keptSegmentIndices.length;
    final excludedCount = state.excludedSegments.length;

    state = state.copyWith(isSaving: true);
    try {
      if (isWeb) {
        await _saveServerSide(recording);
      } else {
        await _saveLocally(recording, localeTag, saveMode);
      }
      return TrimSaveSucceeded(
        mode: saveMode,
        keptCount: keptCount,
        excludedCount: excludedCount,
      );
    } on Object catch (e) {
      if (!_disposed) state = state.copyWith(isSaving: false);
      return TrimSaveFailed(e);
    }
  }

  Future<void> _saveServerSide(LocalRecordingEntity recording) async {
    final apiRepo = _apiRepo;
    final serverId = recording.serverId ?? recording.id;
    final kept = state.keptSegmentIndices;
    final hasGain = isAudibleGain(state.gainDb);

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

  Future<void> _saveLocally(
    LocalRecordingEntity recording,
    String localeTag,
    TrimSaveMode mode,
  ) async {
    // Capture every dependency before the first await: the notifier is
    // autoDispose, so reading ref after a suspension could throw, yet the save
    // must still commit even if the user navigates away mid-export.
    final save = _LocalSave(
      recording: recording,
      originalTitle:
          recording.title ?? defaultRecordingTitle(locale: localeTag),
      localRepo: _localRepo,
      triggerUpload: ref.read(syncNotifierProvider.notifier).processQueue,
      boostPersisterFactory: _boostPersisterFactory,
      saveAsNewPersisterFactory: ref.read(recordingSaveAsNewPersisterProvider),
      splitPersisterFactory: _persisterFactory,
      apiRepo: _apiRepo,
    );
    switch (mode) {
      case TrimSaveMode.removeStretch:
        final joined = await _joiner(_joinRequest(recording));
        await save.replaceAudio(joined);
      case TrimSaveMode.saveAsNew:
        final joined = await _joiner(_joinRequest(recording));
        await save.addAsNewRecording(joined);
      case TrimSaveMode.boostOnly:
        final boosted = await _exporter(_exportRequest(save, boostOnly: true));
        await save.replaceAudio(
          EditedAudio(
            localFilePath: boosted.single.localFilePath,
            durationSeconds: boosted.single.durationSeconds,
            fileSizeBytes: boosted.single.fileSizeBytes,
          ),
        );
      case TrimSaveMode.split:
        final specs = await _exporter(_exportRequest(save, boostOnly: false));
        await save.splitInto(specs);
    }
  }

  JoinKeptRangesRequest _joinRequest(LocalRecordingEntity recording) =>
      JoinKeptRangesRequest(
        sourceFilePath: recording.localFilePath,
        keptRanges: [
          for (final i in state.keptSegmentIndices)
            KeptRange(
              startSeconds: state.segmentStart(i).inMilliseconds / 1000.0,
              endSeconds: state.segmentEnd(i).inMilliseconds / 1000.0,
            ),
        ],
        gainDb: state.gainDb,
      );

  ExportLocalSegmentsRequest _exportRequest(
    _LocalSave save, {
    required bool boostOnly,
  }) => ExportLocalSegmentsRequest(
    sourceFilePath: save.recording.localFilePath,
    segments: [
      for (final i in state.keptSegmentIndices)
        SegmentExportSpec(
          startSeconds: state.segmentStart(i).inMilliseconds / 1000.0,
          endSeconds: state.segmentEnd(i).inMilliseconds / 1000.0,
          genreOverride: state.effectiveGenre(i),
          subcategoryOverride: state.effectiveSubcategory(i),
          registerOverride: state.effectiveRegister(i),
        ),
    ],
    gainDb: state.gainDb,
    boostOnly: boostOnly,
    originalTitle: save.originalTitle,
    parentGenreId: save.recording.genreId,
  );
}

class _LocalSave {
  const _LocalSave({
    required this.recording,
    required this.originalTitle,
    required this.localRepo,
    required this.triggerUpload,
    required this.boostPersisterFactory,
    required this.saveAsNewPersisterFactory,
    required this.splitPersisterFactory,
    required this.apiRepo,
  });

  final LocalRecordingEntity recording;
  final String originalTitle;
  final LocalRecordingRepository localRepo;
  final Future<void> Function() triggerUpload;
  final RecordingBoostPersisterFactory boostPersisterFactory;
  final RecordingSaveAsNewPersisterFactory saveAsNewPersisterFactory;
  final RecordingSplitPersisterFactory splitPersisterFactory;
  final RecordingApiRepository apiRepo;

  // The recording keeps its identity and only its audio changes (ENG-402): its
  // own persister, never the split's, so no remote delete can reach a
  // recording that was never replaced.
  Future<void> replaceAudio(EditedAudio audio) =>
      boostPersisterFactory(
        localRepo: localRepo,
        triggerUpload: triggerUpload,
        trashPrevious: (r) => RecordingTrash.putInTrash(
          sourcePath: r.localFilePath,
          metadata: _trashMetadata(r, replacedBy: audio.localFilePath),
        ),
      ).persist(
        recording: recording,
        newFilePath: audio.localFilePath,
        newDurationSeconds: audio.durationSeconds,
        newFileSizeBytes: audio.fileSizeBytes,
        newFormat: audio.format,
      );

  Future<void> splitInto(List<SplitSegmentSpec> segments) =>
      splitPersisterFactory(
        localRepo: localRepo,
        apiRepo: apiRepo,
        triggerUpload: triggerUpload,
        trashParent: (parent) => RecordingTrash.putInTrash(
          sourcePath: parent.localFilePath,
          metadata: _trashMetadata(parent),
        ),
      ).persist(parent: recording, segments: segments);

  Future<void> addAsNewRecording(EditedAudio audio) =>
      saveAsNewPersisterFactory(
        localRepo: localRepo,
        triggerUpload: triggerUpload,
      ).persist(
        original: recording,
        originalTitle: originalTitle,
        audio: audio,
      );
}

Map<String, dynamic> _trashMetadata(
  LocalRecordingEntity r, {
  String? replacedBy,
}) => {
  'id': r.id,
  'title': r.title,
  'description': r.description,
  'projectId': r.projectId,
  'genreId': r.genreId,
  'subcategoryId': r.subcategoryId,
  'registerId': r.registerId,
  'secondaryGenreId': r.secondaryGenreId,
  'secondarySubcategoryId': r.secondarySubcategoryId,
  'secondaryRegisterId': r.secondaryRegisterId,
  'storytellerId': r.storytellerId,
  'userId': r.userId,
  'durationSeconds': r.durationSeconds,
  'fileSizeBytes': r.fileSizeBytes,
  'format': r.format,
  'serverId': r.serverId,
  'gcsUrl': r.gcsUrl,
  'recordedAt': r.recordedAt.toIso8601String(),
  'replacedBy': ?replacedBy,
};
