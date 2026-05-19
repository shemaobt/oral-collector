import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
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
    await apiRepo.updateRecording(id, title: trimmed);
    return SaveTitleResult.saved;
  }

  await localRepo!.updateRecording(
    recordingId,
    LocalRecordingsCompanion(title: Value(trimmed)),
  );

  if (isOnline && serverId != null && serverId.isNotEmpty) {
    try {
      await apiRepo.updateRecording(serverId, title: trimmed);
      return SaveTitleResult.saved;
    } on ForbiddenException {
      rethrow;
    } catch (_) {
      return SaveTitleResult.savedLocallyOnly;
    }
  }

  return SaveTitleResult.saved;
}
