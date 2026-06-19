import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/database/app_database.dart';
import '../../../storyteller/domain/entities/storyteller.dart';

/// Load + resolution state for the recording detail screen, extracted from the
/// screen so the orchestration can live in [RecordingDetailNotifier]. Keeps the
/// raw [LocalRecording] row (the swap to LocalRecordingEntity is F5a/ENG-199).
///
/// No value `==`/`hashCode`: there is no `.distinct()` consumer, and identity
/// equality reproduces the screen's original `setState` (which rebuilt on every
/// mutation), so the rebuild cadence is unchanged.
@immutable
class RecordingDetailState {
  const RecordingDetailState({
    this.recording,
    this.isLoading = true,
    this.resolvedStoryteller,
  });

  final LocalRecording? recording;
  final bool isLoading;
  final Storyteller? resolvedStoryteller;

  RecordingDetailState copyWith({
    LocalRecording? recording,
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
