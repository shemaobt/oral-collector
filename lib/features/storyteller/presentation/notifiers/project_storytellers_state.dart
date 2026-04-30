import '../../domain/entities/storyteller.dart';

class ProjectStorytellersState {
  final String? projectId;
  final List<Storyteller> storytellers;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  const ProjectStorytellersState({
    this.projectId,
    this.storytellers = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.error,
  });

  ProjectStorytellersState copyWith({
    String? projectId,
    List<Storyteller>? storytellers,
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
  }) {
    return ProjectStorytellersState(
      projectId: projectId ?? this.projectId,
      storytellers: storytellers ?? this.storytellers,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
