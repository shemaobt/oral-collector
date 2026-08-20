import '../../../../core/database/app_database.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import 'audio_path_resolver.dart';

/// Whether [session] still holds audio somebody could get back — the finalized
/// recording it is anchored to, or one of [segmentPaths] the sources were left
/// in.
///
/// The question is deliberately "is the audio there", never "is the anchor
/// column set". A deliberate discard deletes the file and leaves the column
/// written (nothing clears it), so a non-null check would turn that path into
/// never-discards and the app would pile up dead session rows nothing cleans —
/// trading lost audio for permanent litter (ENG-521).
///
/// The anchor is resolved through [resolveRecordingPath] rather than stat'd
/// literally, because the documents container moves on reinstall/restore and an
/// absolute path stored in an earlier run would declare live audio gone.
Future<bool> sessionHoldsReachableAudio(
  RecordingSession session,
  List<String> segmentPaths,
) async {
  final anchor = session.finalizedAudioPath;
  if (anchor != null && await resolveRecordingPath(anchor) != null) return true;
  for (final path in segmentPaths) {
    if (await file_ops.fileExists(path)) return true;
  }
  return false;
}
