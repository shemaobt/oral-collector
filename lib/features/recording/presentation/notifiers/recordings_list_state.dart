import '../../../../core/database/app_database.dart';
import '../../domain/entities/classification.dart';

enum StatusFilter { all, pending, uploaded, needsCleaning, unclassified }

class RecordingsListState {
  final List<LocalRecording> recordings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? selectedGenreId;
  final String? selectedSubcategoryId;
  final String? selectedStorytellerId;
  final String? selectedUserId;
  final StatusFilter selectedFilter;
  final String searchQuery;

  const RecordingsListState({
    this.recordings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.selectedGenreId,
    this.selectedSubcategoryId,
    this.selectedStorytellerId,
    this.selectedUserId,
    this.selectedFilter = StatusFilter.all,
    this.searchQuery = '',
  });

  RecordingsListState copyWith({
    List<LocalRecording>? recordings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? selectedGenreId,
    String? selectedSubcategoryId,
    String? selectedStorytellerId,
    String? selectedUserId,
    StatusFilter? selectedFilter,
    String? searchQuery,
    bool clearGenreId = false,
    bool clearSubcategoryId = false,
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
      selectedSubcategoryId: clearSubcategoryId
          ? null
          : (selectedSubcategoryId ?? this.selectedSubcategoryId),
      selectedStorytellerId: clearStorytellerId
          ? null
          : (selectedStorytellerId ?? this.selectedStorytellerId),
      selectedUserId: clearUserId
          ? null
          : (selectedUserId ?? this.selectedUserId),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  int get activeFilterCount {
    var count = 0;
    if (selectedFilter != StatusFilter.all) count++;
    if (selectedGenreId != null) count++;
    if (selectedSubcategoryId != null) count++;
    if (selectedStorytellerId != null) count++;
    if (selectedUserId != null) count++;
    return count;
  }

  List<LocalRecording> get filteredRecordings {
    var list = recordings;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) {
        final title = (r.title ?? '').toLowerCase();
        final desc = (r.description ?? '').toLowerCase();
        return title.contains(q) || desc.contains(q);
      }).toList();
    }

    if (selectedGenreId != null) {
      list = list.where((r) => r.genreId == selectedGenreId).toList();
    }

    if (selectedSubcategoryId != null) {
      list = list
          .where((r) => r.subcategoryId == selectedSubcategoryId)
          .toList();
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
