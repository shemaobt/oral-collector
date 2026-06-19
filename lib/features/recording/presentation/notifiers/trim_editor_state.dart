import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/local_recording_entity.dart';
import '../trim_edit_decision.dart';

/// Editing + load state for the trim editor, extracted from the screen so the
/// orchestration can live in [TrimEditorNotifier]. The pure derivations the
/// screen used to compute inline (boundaries, segment timing, effective
/// taxonomy, the save [decision]) are getters here so the widget and the
/// notifier read them identically.
///
/// No value `==`/`hashCode`: there is no `.distinct()` consumer, and identity
/// equality reproduces the screen's original `setState` (which rebuilt on every
/// mutation), so the rebuild cadence is unchanged.
@immutable
class TrimEditorState {
  const TrimEditorState({
    this.recording,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.loadError,
    this.totalDuration = Duration.zero,
    this.splitPoints = const [],
    this.excludedSegments = const {},
    this.gainDb = 0.0,
    this.segGenreBySig = const {},
    this.segSubcatBySig = const {},
    this.segRegisterBySig = const {},
  });

  final LocalRecordingEntity? recording;
  final bool isLoading;
  final bool isSaving;

  /// A hardcoded "audio unavailable" message (the screen's two literals).
  final String? errorMessage;

  /// A server-fetch failure; the widget localizes it via `friendlyErrorFor`.
  final Object? loadError;

  final Duration totalDuration;
  final List<double> splitPoints;
  final Set<int> excludedSegments;
  final double gainDb;
  final Map<String, String?> segGenreBySig;
  final Map<String, String?> segSubcatBySig;
  final Map<String, String?> segRegisterBySig;

  List<double> get sortedSplits => [...splitPoints]..sort();

  List<double> get boundaries => [0.0, ...sortedSplits, 1.0];

  int get segmentCount => boundaries.length - 1;

  int get keptCount => segmentCount - excludedSegments.length;

  List<int> get keptSegmentIndices => [
    for (var i = 0; i < segmentCount; i++)
      if (!excludedSegments.contains(i)) i,
  ];

  Duration segmentStart(int i) => Duration(
    milliseconds: (boundaries[i] * totalDuration.inMilliseconds).round(),
  );

  Duration segmentEnd(int i) => Duration(
    milliseconds: (boundaries[i + 1] * totalDuration.inMilliseconds).round(),
  );

  Duration segmentDuration(int i) => segmentEnd(i) - segmentStart(i);

  String sigAt(double midpointFraction) => _sig(midpointFraction);

  String sigForSegment(int i) =>
      _sig((boundaries[i] + boundaries[i + 1]) / 2.0);

  String effectiveGenre(int i) {
    final sig = sigForSegment(i);
    final v = segGenreBySig.containsKey(sig)
        ? segGenreBySig[sig]
        : recording?.genreId;
    return v ?? recording?.genreId ?? '';
  }

  String? effectiveSubcategory(int i) {
    final sig = sigForSegment(i);
    return segSubcatBySig.containsKey(sig)
        ? segSubcatBySig[sig]
        : recording?.subcategoryId;
  }

  String? effectiveRegister(int i) {
    final sig = sigForSegment(i);
    return segRegisterBySig.containsKey(sig)
        ? segRegisterBySig[sig]
        : recording?.registerId;
  }

  TrimEditDecision get decision => TrimEditDecision(
    splitPoints: splitPoints,
    excludedSegments: excludedSegments,
    gainDb: gainDb,
    totalDuration: totalDuration,
  );

  TrimEditorState copyWith({
    LocalRecordingEntity? recording,
    bool clearRecording = false,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    Object? loadError,
    bool clearLoadError = false,
    Duration? totalDuration,
    List<double>? splitPoints,
    Set<int>? excludedSegments,
    double? gainDb,
    Map<String, String?>? segGenreBySig,
    Map<String, String?>? segSubcatBySig,
    Map<String, String?>? segRegisterBySig,
  }) {
    return TrimEditorState(
      recording: clearRecording ? null : (recording ?? this.recording),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      totalDuration: totalDuration ?? this.totalDuration,
      splitPoints: splitPoints ?? this.splitPoints,
      excludedSegments: excludedSegments ?? this.excludedSegments,
      gainDb: gainDb ?? this.gainDb,
      segGenreBySig: segGenreBySig ?? this.segGenreBySig,
      segSubcatBySig: segSubcatBySig ?? this.segSubcatBySig,
      segRegisterBySig: segRegisterBySig ?? this.segRegisterBySig,
    );
  }
}

String _sig(double midpointFraction) => midpointFraction.toStringAsFixed(3);

/// Remaps per-segment taxonomy overrides from the old segmentation onto the new
/// one by nearest segment midpoint (within 0.02). Used when split points change
/// so a small edit keeps a segment's overrides while a re-split drops them.
Map<String, String?> remapTaxonomyBySig(
  Map<String, String?> previous,
  List<double> previousBoundaries,
  List<double> newBoundaries,
) {
  final result = <String, String?>{};
  final previousSegCount = previousBoundaries.length - 1;
  final newSegCount = newBoundaries.length - 1;
  final previousMids = <double>[
    for (var i = 0; i < previousSegCount; i++)
      (previousBoundaries[i] + previousBoundaries[i + 1]) / 2.0,
  ];

  for (var j = 0; j < newSegCount; j++) {
    final newMid = (newBoundaries[j] + newBoundaries[j + 1]) / 2.0;
    double bestDist = double.infinity;
    int? bestIdx;
    for (var i = 0; i < previousMids.length; i++) {
      final d = (newMid - previousMids[i]).abs();
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    if (bestIdx == null || bestDist > 0.02) continue;
    final oldSig = _sig(previousMids[bestIdx]);
    if (!previous.containsKey(oldSig)) continue;
    final newSig = _sig(newMid);
    result[newSig] = previous[oldSig];
  }
  return result;
}
