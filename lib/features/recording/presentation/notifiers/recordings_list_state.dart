import '../../../../core/database/app_database.dart';
import '../../domain/entities/classification.dart';

enum StatusFilter { all, pending, uploaded, needsCleaning, unclassified }

class RecordingsListState {
  final List<LocalRecording> recordings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? selectedGenreId;
  final String? selectedStorytellerId;
  final String? selectedUserId;
  final StatusFilter selectedFilter;

  const RecordingsListState({
    this.recordings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.selectedGenreId,
    this.selectedStorytellerId,
    this.selectedUserId,
    this.selectedFilter = StatusFilter.all,
  });

  RecordingsListState copyWith({
    List<LocalRecording>? recordings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? selectedGenreId,
    String? selectedStorytellerId,
    String? selectedUserId,
    StatusFilter? selectedFilter,
    bool clearGenreId = false,
    bool clearStorytellerId = false,
    bool clearUserId = false,
  }) {
    return RecordingsListState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      selectedGenreId: clearGenreId
          ? null
          : (selectedGenreId ?? this.selectedGenreId),
      selectedStorytellerId: clearStorytellerId
          ? null
          : (selectedStorytellerId ?? this.selectedStorytellerId),
      selectedUserId: clearUserId
          ? null
          : (selectedUserId ?? this.selectedUserId),
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  int get activeFilterCount {
    var count = 0;
    if (selectedFilter != StatusFilter.all) count++;
    if (selectedGenreId != null) count++;
    if (selectedStorytellerId != null) count++;
    if (selectedUserId != null) count++;
    return count;
  }

  List<LocalRecording> get filteredRecordings {
    var list = recordings;

    if (selectedGenreId != null) {
      list = list.where((r) => r.genreId == selectedGenreId).toList();
    }

    if (selectedStorytellerId != null) {
      list = list
          .where((r) => r.storytellerId == selectedStorytellerId)
          .toList();
    }

    if (selectedUserId != null) {
      list = list.where((r) => r.userId == selectedUserId).toList();
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
