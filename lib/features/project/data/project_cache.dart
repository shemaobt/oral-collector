import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/language.dart';
import '../domain/entities/project.dart';

/// Snapshot of the cached projects + languages. Null from [ProjectCache.read]
/// means nothing is cached or the cache is unreadable.
class ProjectCacheSnapshot {
  final List<Project> projects;
  final List<Language> languages;

  const ProjectCacheSnapshot({required this.projects, required this.languages});
}

abstract class ProjectCache {
  /// Null when nothing is cached or the cache is unreadable.
  Future<ProjectCacheSnapshot?> read();
  Future<void> write(List<Project> projects, List<Language> languages);
}

class SharedPreferencesProjectCache implements ProjectCache {
  static const _cachedProjectsKey = 'cached_projects';
  static const _cachedLanguagesKey = 'cached_languages';

  @override
  Future<ProjectCacheSnapshot?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProjects = prefs.getString(_cachedProjectsKey);
    if (rawProjects == null) return null;
    try {
      final projects = (jsonDecode(rawProjects) as List<dynamic>)
          .map((j) => Project.fromJson(j as Map<String, dynamic>))
          .toList();
      final rawLanguages = prefs.getString(_cachedLanguagesKey);
      final languages = rawLanguages != null
          ? (jsonDecode(rawLanguages) as List<dynamic>)
                .map((j) => Language.fromJson(j as Map<String, dynamic>))
                .toList()
          : <Language>[];
      return ProjectCacheSnapshot(projects: projects, languages: languages);
    } catch (_) {
      return null; // corrupt cache → treat as empty (incl. cast Errors)
    }
  }

  @override
  Future<void> write(List<Project> projects, List<Language> languages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedProjectsKey,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
    await prefs.setString(
      _cachedLanguagesKey,
      jsonEncode(languages.map((l) => l.toJson()).toList()),
    );
  }
}
