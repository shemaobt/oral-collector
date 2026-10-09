import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/recording_title.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../repositories/local_recording_repository.dart';
import 'joined_audio_exporter.dart';

class RecordingSaveAsNewPersister {
  const RecordingSaveAsNewPersister({
    required this.localRepo,
    required this.triggerUpload,
  });

  final LocalRecordingRepository localRepo;
  final Future<void> Function() triggerUpload;

  Future<String> persist({
    required LocalRecordingEntity original,
    required String originalTitle,
    required EditedAudio audio,
  }) async {
    final projectRecordings = await localRepo.getAllRecordings(
      original.projectId,
    );
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${original.genreId.hashCode}';
    await localRepo.insertRecordingFromEdit(
      parent: original,
      recording: SplitSegmentSpec(
        id: id,
        title: nextNumberedTitle(
          projectRecordings.map((r) => r.title),
          originalTitle,
        ),
        localFilePath: audio.localFilePath,
        durationSeconds: audio.durationSeconds,
        fileSizeBytes: audio.fileSizeBytes,
        format: audio.format,
      ),
    );
    unawaited(triggerUpload());
    return id;
  }
}

typedef RecordingSaveAsNewPersisterFactory =
    RecordingSaveAsNewPersister Function({
      required LocalRecordingRepository localRepo,
      required Future<void> Function() triggerUpload,
    });

final recordingSaveAsNewPersisterProvider =
    Provider<RecordingSaveAsNewPersisterFactory>(
      (_) => RecordingSaveAsNewPersister.new,
    );
