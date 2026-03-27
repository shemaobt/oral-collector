import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../project/presentation/notifiers/project_notifier.dart';
import '../../data/providers.dart';
import '../../data/repositories/local_recording_repository.dart';
import '../../domain/entities/server_recording.dart';
import '../../domain/repositories/recording_api_repository.dart';
import 'recordings_list_state.dart';

const _pageSize = 50;

final recordingsListNotifierProvider =
    NotifierProvider<RecordingsListNotifier, RecordingsListState>(
      RecordingsListNotifier.new,
    );

class RecordingsListNotifier extends Notifier<RecordingsListState> {
  RecordingApiRepository get _apiRepo =>
      ref.read(recordingApiRepositoryProvider);
  LocalRecordingRepository get _localRepo =>
      ref.read(localRecordingRepositoryProvider);

  int _serverOffset = 0;
  List<LocalRecording> _localOnlyRecordings = [];
  final Set<String> _serverIds = {};

  @override
  RecordingsListState build() => const RecordingsListState();

  Future<void> fetchRecordings() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    _serverOffset = 0;
    _serverIds.clear();
    _localOnlyRecordings = [];

    try {
      final merged = await _fetchAndMerge(projectId);
      state = state.copyWith(recordings: merged, isLoading: false);
    } catch (e) {
      await _fallbackToLocal(projectId);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final serverPage = await _apiRepo.listRecordings(
        projectId,
        offset: _serverOffset,
        limit: _pageSize,
      );

      final hasMore = serverPage.length >= _pageSize;
      _serverOffset += serverPage.length;

      for (final s in serverPage) {
        _serverIds.add(s.id);
      }

      final newServerAsLocal = _convertServerRecordings(serverPage);
      final currentRecordings = List<LocalRecording>.from(state.recordings);
      currentRecordings.addAll(newServerAsLocal);

      state = state.copyWith(
        recordings: currentRecordings,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<List<LocalRecording>> _fetchAndMerge(String projectId) async {
    final serverRecordings = await _apiRepo.listRecordings(
      projectId,
      offset: 0,
      limit: _pageSize,
    );
    final localRecordings = await _localRepo.getAllRecordings(projectId);

    final hasMore = serverRecordings.length >= _pageSize;
    _serverOffset = serverRecordings.length;

    for (final s in serverRecordings) {
      _serverIds.add(s.id);
    }

    _localOnlyRecordings = localRecordings
        .where(
          (r) =>
              (r.uploadStatus == 'local' ||
                  r.uploadStatus == 'uploading' ||
                  r.uploadStatus == 'failed') &&
              (r.serverId == null || !_serverIds.contains(r.serverId)),
        )
        .toList();

    final serverAsLocal = _convertServerRecordings(serverRecordings);
    final merged = [..._localOnlyRecordings, ...serverAsLocal];
    merged.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    state = state.copyWith(hasMore: hasMore);
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
            registerId: s.registerId,
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
            uploadedBytes: 0,
          ),
        )
        .toList();
  }

  Future<void> _fallbackToLocal(String projectId) async {
    try {
      final recordings = await _localRepo.getAllRecordings(projectId);
      state = state.copyWith(
        recordings: recordings,
        isLoading: false,
        hasMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
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

  Future<int> clearStaleRecordings() async {
    final projectId = ref.read(projectNotifierProvider).activeProject?.id;
    if (projectId == null) return 0;

    final serverDeleted = await _apiRepo.clearStaleRecordings(projectId);
    await _localRepo.deleteStaleRecordings(projectId);
    await fetchRecordings();
    return serverDeleted;
  }
}
