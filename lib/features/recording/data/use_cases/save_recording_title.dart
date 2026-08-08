import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/app_exception.dart' show ConflictException;
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
  final hasServerCopy = serverId != null && serverId.isNotEmpty;

  if (isOnline && hasServerCopy) {
    try {
      await apiRepo.updateRecording(
        serverId,
        UpdateRecordingRequest(title: trimmed),
      );
    } on ForbiddenException {
      rethrow;
    } on ConflictException {
      // A taken title is a decision for the caller, not something a local-only
      // save can paper over — the local row would then disagree with the server.
      rethrow;
    } catch (_) {
      await localRepo!.updateRecording(recordingId, localCompanion);
      return SaveTitleResult.savedLocallyOnly;
    }
    await localRepo!.updateRecording(recordingId, localCompanion);
    return SaveTitleResult.saved;
  }

  await localRepo!.updateRecording(recordingId, localCompanion);
  // Offline with a server copy is a local-only save, exactly as
  // saveRecordingDescription reports it: the server holds this recording and
  // was not told. Without a server copy the rename rides along on the upload,
  // so nothing is pending (ENG-399).
  return hasServerCopy
      ? SaveTitleResult.savedLocallyOnly
      : SaveTitleResult.saved;
}
