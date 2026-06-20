import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/observability/error_reporter.dart';
import '../../data/project_cache.dart';
import '../../data/providers.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_update.dart';
import '../../domain/repositories/project_repository.dart';
import 'project_state.dart';

final projectNotifierProvider = NotifierProvider<ProjectNotifier, ProjectState>(
  ProjectNotifier.new,
);

class ProjectNotifier extends Notifier<ProjectState> {
  static const _activeProjectIdKey = 'active_project_id';

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);
  ProjectCache get _cache => ref.read(projectCacheProvider);

  @override
  ProjectState build() {
    _hydrateFromCache();
    return const ProjectState();
  }

  Future<void> _hydrateFromCache() async {
    final cached = await _cache.read();
    if (cached == null) return;
    // A completed fetch is authoritative: never let a late hydration clobber it.
    if (state.lastFetched != null) return;

    final active = await _restoreActiveProject(cached.projects);
    // _restoreActiveProject awaits prefs; a fetch can complete during that gap.
    // Re-check so the late hydration still can't clobber fresh server data.
    if (state.lastFetched != null) return;

    state = state.copyWith(
      projects: cached.projects,
      languages: cached.languages,
      activeProject: active,
      clearActiveProject: active == null,
    );
  }

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

      await _cache.write(enriched, languages);

      state = state.copyWith(
        projects: enriched,
        languages: languages,
        activeProject: active,
        isLoading: false,
        clearActiveProject: active == null,
        lastFetched: DateTime.now(),
      );
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false);
      // Fire-and-forget: handleUnauthorized pode propagar uma falha transitória
      // de refresh (ENG-141); aqui ela é ignorada (sessão preservada). Só
      // Exceptions, não Errors, para não mascarar bugs.
      unawaited(
        ref
            .read(authNotifierProvider.notifier)
            .handleUnauthorized()
            .catchError((_) => false, test: (e) => e is Exception),
      );
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(error: e);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> updateProject(String id, ProjectUpdate update) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _repo.updateProject(id, update);
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
    } on Exception catch (e, st) {
      ref.read(errorReporterProvider).reportError(e, st);
      state = state.copyWith(isLoading: false, error: e);
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
