import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/local_recording_entity.dart';
import '../repositories/local_recording_repository.dart';

/// Post-FFmpeg pipeline of a trim-editor save with no cut points: points the
/// recording at its re-encoded audio, queues that audio to go back up against
/// the recording the server already has, archives the file it replaced, then
/// kicks the upload queue.
///
/// Sibling of `RecordingSplitPersister`, deliberately not a mode of it (ENG-402):
/// a boost keeps the recording, a split replaces it, and the difference runs
/// through every step. It holds no `RecordingApiRepository` because this path
/// has nothing to retire on the server — that missing call is the fix. The
/// split's remote delete is best-effort and fails silently offline, so a boost
/// that went through it left the server holding both the original and the new
/// recording, and the project counted the story twice.
class RecordingBoostPersister {
  final LocalRecordingRepository localRepo;
  final Future<void> Function() triggerUpload;

  /// Archives the audio the boost replaced. Optional so a caller without a
  /// filesystem (tests, web) can leave it out.
  final Future<void> Function(LocalRecordingEntity recording)? trashPrevious;

  const RecordingBoostPersister({
    required this.localRepo,
    required this.triggerUpload,
    this.trashPrevious,
  });

  Future<void> persist({
    required LocalRecordingEntity recording,
    required String newFilePath,
    required double newDurationSeconds,
    required int newFileSizeBytes,
  }) async {
    await localRepo.replaceAudioAndQueueResend(
      recordingId: recording.id,
      newFilePath: newFilePath,
      newDurationSeconds: newDurationSeconds,
      newFileSizeBytes: newFileSizeBytes,
    );

    // After the write commits, and outside it: a file move cannot be rolled
    // back, so a failed write must never leave the row pointing at audio that
    // has already been moved away. [recording] still names the replaced file —
    // the row does not, any more.
    final trash = trashPrevious;
    if (trash != null) {
      await trash(recording);
    }

    unawaited(triggerUpload());
  }
}

typedef RecordingBoostPersisterFactory =
    RecordingBoostPersister Function({
      required LocalRecordingRepository localRepo,
      required Future<void> Function() triggerUpload,
      Future<void> Function(LocalRecordingEntity recording)? trashPrevious,
    });

/// Injectable so the trim editor's save path can hand off to a fake persister
/// in tests; the default forwards to the real constructor.
final recordingBoostPersisterProvider =
    Provider<RecordingBoostPersisterFactory>(
      (_) => RecordingBoostPersister.new,
    );
