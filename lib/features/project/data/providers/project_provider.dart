import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../repositories/project_repository.dart';

// --- State ---

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
      activeProject:
          clearActiveProject ? null : (activeProject ?? this.activeProject),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// --- Providers ---

final projectRepositoryProvider = Provider<ProjectRepository>(
  (_) => ProjectRepository(),
);

final projectNotifierProvider =
    NotifierProvider<ProjectNotifier, ProjectState>(ProjectNotifier.new);

// --- Notifier ---

class ProjectNotifier extends Notifier<ProjectState> {
  static const _activeProjectIdKey = 'active_project_id';

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  ProjectState build() {
    return const ProjectState();
  }

  /// Fetch all projects the user belongs to, and restore the active project.
  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final projects = await _repo.listProjects();

      // Restore persisted active project
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_activeProjectIdKey);
      Project? active;
      if (savedId != null) {
        active = projects.where((p) => p.id == savedId).firstOrNull;
      }

      state = state.copyWith(
        projects: projects,
        activeProject: active,
        isLoading: false,
        clearActiveProject: active == null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Set the active project and persist its ID.
  Future<void> setActiveProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProjectIdKey, project.id);
    state = state.copyWith(activeProject: project);
  }

  /// Fetch available languages for project creation.
  Future<void> fetchLanguages() async {
    try {
      final languages = await _repo.listLanguages();
      state = state.copyWith(languages: languages);
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Create a new project and add it to the list.
  Future<void> createProject({
    required String name,
    required String languageId,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final project = await _repo.createProject(
        name: name,
        languageId: languageId,
        description: description,
      );
      state = state.copyWith(
        projects: [...state.projects, project],
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Update a project by ID and refresh it in the list.
  Future<void> updateProject(
    String id,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _repo.updateProject(id, data);
      final updatedList = state.projects.map((p) {
        return p.id == id ? updated : p;
      }).toList();

      // Also update activeProject if it was the one modified
      final activeUpdated =
          state.activeProject?.id == id ? updated : state.activeProject;

      state = state.copyWith(
        projects: updatedList,
        activeProject: activeUpdated,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
