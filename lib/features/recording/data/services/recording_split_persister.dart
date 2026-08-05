import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/local_recording_entity.dart';
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
  final Future<void> Function(LocalRecordingEntity parent)? trashParent;

  const RecordingSplitPersister({
    required this.localRepo,
    required this.apiRepo,
    required this.triggerUpload,
    this.trashParent,
  });

  Future<List<String>> persist({
    required LocalRecordingEntity parent,
    required List<SplitSegmentSpec> segments,
  }) async {
    // One transaction: insert the children and delete the parent row together,
    // so a failure can't leave orphaned children beside a surviving parent.
    final ids = await localRepo.splitRecordingReplacingParent(
      parent: parent,
      segments: segments,
    );

    // Archive the (now-orphaned) parent audio AFTER the split commits. The trash
    // callback only reads the parent object/file, so it doesn't need the row;
    // running it post-commit means a split failure never leaves the parent's
    // audio moved out from under a surviving row.
    final trash = trashParent;
    if (trash != null) {
      await trash(parent);
    }

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

typedef RecordingSplitPersisterFactory =
    RecordingSplitPersister Function({
      required LocalRecordingRepository localRepo,
      required RecordingApiRepository apiRepo,
      required Future<void> Function() triggerUpload,
      Future<void> Function(LocalRecordingEntity parent)? trashParent,
    });

/// Injectable so the trim editor's save path can hand off to a fake persister
/// in tests; the default forwards to the real constructor.
final recordingSplitPersisterProvider =
    Provider<RecordingSplitPersisterFactory>(
      (_) => RecordingSplitPersister.new,
    );
