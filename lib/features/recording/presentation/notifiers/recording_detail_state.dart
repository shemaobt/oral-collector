import 'package:flutter/foundation.dart' show immutable;

import '../../../storyteller/domain/entities/storyteller.dart';
import '../../domain/entities/local_recording_entity.dart';

/// Load + resolution state for the recording detail screen, extracted from the
/// screen so the orchestration can live in [RecordingDetailNotifier]. Holds the
/// row-decoupled [LocalRecordingEntity] (ENG-199/F5a).
///
/// No value `==`/`hashCode`: there is no `.distinct()` consumer here (dedup
/// lives upstream in `watchRecordingEntityById`), and identity equality
/// reproduces the screen's original `setState` (which rebuilt on every
/// mutation), so the rebuild cadence is unchanged.
@immutable
class RecordingDetailState {
  const RecordingDetailState({
    this.recording,
    this.isLoading = true,
    this.resolvedStoryteller,
  });

  final LocalRecordingEntity? recording;
  final bool isLoading;
  final Storyteller? resolvedStoryteller;

  RecordingDetailState copyWith({
    LocalRecordingEntity? recording,
    bool clearRecording = false,
    bool? isLoading,
    Storyteller? resolvedStoryteller,
    bool clearStoryteller = false,
  }) {
    return RecordingDetailState(
      recording: clearRecording ? null : (recording ?? this.recording),
      isLoading: isLoading ?? this.isLoading,
      resolvedStoryteller: clearStoryteller
          ? null
          : (resolvedStoryteller ?? this.resolvedStoryteller),
    );
  }
}
