import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/repositories/recording_api_repository.dart';
import 'recordings_list_state.dart';

final recordingsListNotifierProvider =
    NotifierProvider<RecordingsListNotifier, RecordingsListState>(
      RecordingsListNotifier.new,
    );

class RecordingsListNotifier extends Notifier<RecordingsListState> {
  RecordingApiRepository get _apiRepo =>
      ref.read(recordingApiRepositoryProvider);
  LocalRecordingRepository get _localRepo =>
      ref.read(localRecordingRepositoryProvider);

  @override
  RecordingsListState build() => const RecordingsListState();

  Future<void> fetchRecordings() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final merged = await _fetchAndMerge(projectId);
      state = state.copyWith(recordings: merged, isLoading: false);
    } catch (e) {
      await _fallbackToLocal(projectId);
    }
  }

  Future<List<LocalRecording>> _fetchAndMerge(String projectId) async {
    final serverRecordings = await _apiRepo.listRecordings(projectId);
    final localRecordings = await _localRepo.getAllRecordings(projectId);
    final localOnly = localRecordings
        .where(
          (r) =>
              r.uploadStatus == 'local' ||
              r.uploadStatus == 'uploading' ||
              r.uploadStatus == 'failed',
        )
        .toList();

    final serverAsLocal = _convertServerRecordings(serverRecordings);
    final merged = [...localOnly, ...serverAsLocal];
    merged.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return merged;
  }

  List<LocalRecording> _convertServerRecordings(
    List<ServerRecording> recordings,
  ) {
    return recordings
        .map(
          (s) => LocalRecording(
            id: s.id,
            projectId: s.projectId,
            genreId: s.genreId,
            subcategoryId: s.subcategoryId,
            title: s.title,
            durationSeconds: s.durationSeconds,
            fileSizeBytes: s.fileSizeBytes,
            format: s.format,
            localFilePath: '',
            uploadStatus: s.uploadStatus,
            serverId: s.id,
            gcsUrl: s.gcsUrl,
            cleaningStatus: s.cleaningStatus,
            recordedAt: s.recordedAt,
            createdAt: s.recordedAt,
            retryCount: 0,
          ),
        )
        .toList();
  }

  Future<void> _fallbackToLocal(String projectId) async {
    try {
      final recordings = await _localRepo.getAllRecordings(projectId);
      state = state.copyWith(recordings: recordings, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setGenreFilter(String? genreId) {
    if (genreId == null) {
      state = state.copyWith(clearGenreId: true);
    } else {
      state = state.copyWith(selectedGenreId: genreId);
    }
  }

  void setStatusFilter(StatusFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}
