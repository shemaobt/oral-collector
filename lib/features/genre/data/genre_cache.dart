import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/genre.dart';

abstract class GenreCache {
  /// Null when nothing is cached or the cache is unreadable.
  Future<List<Genre>?> read();
  Future<void> write(List<Genre> genres);
}

class SharedPreferencesGenreCache implements GenreCache {
  static const _cachedGenresKey = 'cached_genres';

  @override
  Future<List<Genre>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedGenresKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((j) => Genre.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null; // corrupt cache → treat as empty (incl. cast Errors)
    }
  }

  @override
  Future<void> write(List<Genre> genres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedGenresKey,
      jsonEncode(genres.map((g) => g.toJson()).toList()),
    );
  }
}
