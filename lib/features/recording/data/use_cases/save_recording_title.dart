import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/update_recording_request.dart';
import '../../domain/repositories/recording_api_repository.dart';
import '../repositories/local_recording_repository.dart';

enum SaveTitleResult { saved, savedLocallyOnly, noChange, emptyRejected }

Future<SaveTitleResult> saveRecordingTitle({
  required String recordingId,
  required String? currentTitle,
  required String? serverId,
  required String newTitle,
  required bool isWeb,
  required bool isOnline,
  required RecordingApiRepository apiRepo,
  required LocalRecordingRepository? localRepo,
}) async {
  assert(
    isWeb || localRepo != null,
    'localRepo is required when isWeb is false',
  );

  final trimmed = newTitle.trim();

  if (trimmed.isEmpty) {
    return SaveTitleResult.emptyRejected;
  }

  if (trimmed == (currentTitle ?? '')) {
    return SaveTitleResult.noChange;
  }

  if (isWeb) {
    final id = (serverId != null && serverId.isNotEmpty)
        ? serverId
        : recordingId;
    await apiRepo.updateRecording(id, UpdateRecordingRequest(title: trimmed));
    return SaveTitleResult.saved;
  }

  final localCompanion = LocalRecordingsCompanion(title: Value(trimmed));

  if (isOnline && serverId != null && serverId.isNotEmpty) {
    try {
      await apiRepo.updateRecording(
        serverId,
        UpdateRecordingRequest(title: trimmed),
      );
    } on ForbiddenException {
      rethrow;
    } catch (_) {
      await localRepo!.updateRecording(recordingId, localCompanion);
      return SaveTitleResult.savedLocallyOnly;
    }
    await localRepo!.updateRecording(recordingId, localCompanion);
    return SaveTitleResult.saved;
  }

  await localRepo!.updateRecording(recordingId, localCompanion);
  return SaveTitleResult.saved;
}
