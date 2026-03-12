import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../data/providers.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import 'project_state.dart';

final projectNotifierProvider = NotifierProvider<ProjectNotifier, ProjectState>(
  ProjectNotifier.new,
);

class ProjectNotifier extends Notifier<ProjectState> {
  static const _activeProjectIdKey = 'active_project_id';

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  ProjectState build() => const ProjectState();

  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repo.listProjects(),
        _repo.listLanguages(),
      ]);
      final projects = results[0] as List<Project>;
      final languages = results[1] as List<Language>;

      final enriched = _enrichWithLanguageNames(projects, languages);
      final active = await _restoreActiveProject(enriched);

      state = state.copyWith(
        projects: enriched,
        languages: languages,
        activeProject: active,
        isLoading: false,
        clearActiveProject: active == null,
      );
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      ref.read(authNotifierProvider.notifier).handleUnauthorized();
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setActiveProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProjectIdKey, project.id);
    state = state.copyWith(activeProject: project);
  }

  void setLanguages(List<Language> languages) {
    state = state.copyWith(languages: languages);
  }

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

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _repo.updateProject(id, data);
      final updatedList = state.projects.map((p) {
        return p.id == id ? updated : p;
      }).toList();

      final activeUpdated = state.activeProject?.id == id
          ? updated
          : state.activeProject;

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

  List<Project> _enrichWithLanguageNames(
    List<Project> projects,
    List<Language> languages,
  ) {
    final langMap = {for (final l in languages) l.id: l};
    return projects.map((p) {
      final lang = langMap[p.languageId];
      if (lang != null && p.languageName == null) {
        return Project(
          id: p.id,
          name: p.name,
          languageId: p.languageId,
          languageName: lang.name,
          languageCode: lang.code,
          description: p.description,
          memberCount: p.memberCount,
          recordingCount: p.recordingCount,
          totalDurationSeconds: p.totalDurationSeconds,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();
  }

  Future<Project?> _restoreActiveProject(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_activeProjectIdKey);
    Project? active;
    if (savedId != null) {
      active = projects.where((p) => p.id == savedId).firstOrNull;
    }
    if (active == null && projects.isNotEmpty) {
      active = projects.first;
      await prefs.setString(_activeProjectIdKey, active.id);
    }
    return active;
  }
}
