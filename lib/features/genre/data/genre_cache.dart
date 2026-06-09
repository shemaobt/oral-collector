import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/serialization/parse_list.dart';
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
      return parseList(jsonDecode(raw), Genre.fromJson, context: 'genreCache');
    } on Exception {
      return null; // corrupt cache → treat as empty
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
