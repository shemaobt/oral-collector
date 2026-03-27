import '../../../../core/database/app_database.dart';
import '../../domain/entities/classification.dart';

enum StatusFilter { all, pending, uploaded, needsCleaning, unclassified }

class RecordingsListState {
  final List<LocalRecording> recordings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? selectedGenreId;
  final StatusFilter selectedFilter;

  const RecordingsListState({
    this.recordings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.selectedGenreId,
    this.selectedFilter = StatusFilter.all,
  });

  RecordingsListState copyWith({
    List<LocalRecording>? recordings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? selectedGenreId,
    StatusFilter? selectedFilter,
    bool clearGenreId = false,
  }) {
    return RecordingsListState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      selectedGenreId: clearGenreId
          ? null
          : (selectedGenreId ?? this.selectedGenreId),
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  List<LocalRecording> get filteredRecordings {
    var list = recordings;

    if (selectedGenreId != null) {
      list = list.where((r) => r.genreId == selectedGenreId).toList();
    }

    switch (selectedFilter) {
      case StatusFilter.all:
        break;
      case StatusFilter.pending:
        list = list
            .where(
              (r) =>
                  r.uploadStatus == 'local' ||
                  r.uploadStatus == 'failed' ||
                  r.uploadStatus == 'uploading',
            )
            .toList();
      case StatusFilter.uploaded:
        list = list.where((r) => r.uploadStatus == 'uploaded').toList();
      case StatusFilter.needsCleaning:
        list = list.where((r) => r.cleaningStatus == 'needs_cleaning').toList();
      case StatusFilter.unclassified:
        list = list.where((r) => r.isUnclassified).toList();
    }

    return list;
  }
}
