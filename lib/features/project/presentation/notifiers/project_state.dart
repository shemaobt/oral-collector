import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';

class ProjectState {
  final List<Project> projects;
  final List<Language> languages;
  final Project? activeProject;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.projects = const [],
    this.languages = const [],
    this.activeProject,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Project>? projects,
    List<Language>? languages,
    Project? activeProject,
    bool? isLoading,
    String? error,
    bool clearActiveProject = false,
    bool clearError = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      languages: languages ?? this.languages,
      activeProject: clearActiveProject
          ? null
          : (activeProject ?? this.activeProject),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
