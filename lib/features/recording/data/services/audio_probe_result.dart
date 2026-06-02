import 'package:flutter/foundation.dart';

@immutable
class AudioProbeResult {
  const AudioProbeResult({
    this.durationSeconds,
    this.codec,
    this.playable = false,
    this.diagnostic,
  });

  final double? durationSeconds;
  final String? codec;
  final bool playable;
  final String? diagnostic;

  bool get hasDuration =>
      durationSeconds != null &&
      durationSeconds!.isFinite &&
      durationSeconds! > 0;
}
