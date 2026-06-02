import 'package:flutter/foundation.dart';

enum RecordingPlayerError { fileNotFound, loadFailed }

@immutable
class RecordingPlayerState {
  const RecordingPlayerState({
    this.isLoading = true,
    this.errorKind,
    this.hasAudio = false,
  });

  final bool isLoading;
  final RecordingPlayerError? errorKind;
  final bool hasAudio;

  @override
  bool operator ==(Object other) =>
      other is RecordingPlayerState &&
      other.isLoading == isLoading &&
      other.errorKind == errorKind &&
      other.hasAudio == hasAudio;

  @override
  int get hashCode => Object.hash(isLoading, errorKind, hasAudio);
}
