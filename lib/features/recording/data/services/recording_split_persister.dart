import 'dart:async';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../repositories/local_recording_repository.dart';

/// Post-FFmpeg pipeline of a trim/split save: writes the child rows,
/// moves the parent to local trash (if a callback is provided), removes
/// the parent locally and best-effort remotely, then kicks the upload
/// queue so the new children start uploading without the user having to
/// interact further. Extracted from the trim editor so it can be tested
/// without spinning up the widget.
class RecordingSplitPersister {
  final LocalRecordingRepository localRepo;
  final RecordingApiRepository apiRepo;
  final Future<void> Function() triggerUpload;
  final Future<void> Function(LocalRecording parent)? trashParent;

  const RecordingSplitPersister({
    required this.localRepo,
    required this.apiRepo,
    required this.triggerUpload,
    this.trashParent,
  });

  Future<List<String>> persist({
    required LocalRecording parent,
    required List<SplitSegmentSpec> segments,
  }) async {
    final ids = await localRepo.splitRecording(
      parent: parent,
      segments: segments,
    );

    final trash = trashParent;
    if (trash != null) {
      await trash(parent);
    }

    await localRepo.deleteRecording(parent.id);

    final serverId = parent.serverId;
    if (serverId != null && serverId.isNotEmpty) {
      try {
        await apiRepo.deleteRecording(serverId);
      } catch (_) {}
    }

    unawaited(triggerUpload());

    return ids;
  }
}
