import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';

// --- Data classes ---

class SubcategoryStat {
  final String subcategoryId;
  final double totalDurationSeconds;
  final int recordingCount;
  final double? targetHours;

  const SubcategoryStat({
    required this.subcategoryId,
    required this.totalDurationSeconds,
    required this.recordingCount,
    this.targetHours,
  });
}

class GenreStat {
  final String genreId;
  final double totalDurationSeconds;
  final int recordingCount;
  final Map<String, SubcategoryStat> subcategories;

  const GenreStat({
    required this.genreId,
    required this.totalDurationSeconds,
    required this.recordingCount,
    this.subcategories = const {},
  });
}

// --- State ---

class StatsState {
  final Map<String, GenreStat> genreStats;
  final bool isLoading;

  const StatsState({
    this.genreStats = const {},
    this.isLoading = false,
  });

  StatsState copyWith({
    Map<String, GenreStat>? genreStats,
    bool? isLoading,
  }) {
    return StatsState(
      genreStats: genreStats ?? this.genreStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- Providers ---

final statsNotifierProvider =
    NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);

// --- Notifier ---

class StatsNotifier extends Notifier<StatsState> {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  StatsNotifier({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  @override
  StatsState build() {
    return const StatsState();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch genre stats for the given project from the API.
  Future<void> fetchGenreStats(String projectId) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/oc/projects/$projectId/genre-stats'),
        headers: await _authHeaders(),
      );

      if (response.statusCode != 200) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final genresList = data['genres'] as List<dynamic>? ?? [];
      final subcategoriesList = data['subcategories'] as List<dynamic>? ?? [];

      // Build subcategory stats grouped by genre_id
      final subcatsByGenre = <String, Map<String, SubcategoryStat>>{};
      for (final sub in subcategoriesList) {
        final map = sub as Map<String, dynamic>;
        final genreId = map['genre_id'] as String;
        final subcatId = map['subcategory_id'] as String;
        subcatsByGenre.putIfAbsent(genreId, () => {});
        subcatsByGenre[genreId]![subcatId] = SubcategoryStat(
          subcategoryId: subcatId,
          totalDurationSeconds: (map['duration_seconds'] as num).toDouble(),
          recordingCount: map['recording_count'] as int,
        );
      }

      // Build genre stats map
      final genreStats = <String, GenreStat>{};
      for (final genre in genresList) {
        final map = genre as Map<String, dynamic>;
        final genreId = map['genre_id'] as String;
        genreStats[genreId] = GenreStat(
          genreId: genreId,
          totalDurationSeconds: (map['duration_seconds'] as num).toDouble(),
          recordingCount: map['recording_count'] as int,
          subcategories: subcatsByGenre[genreId] ?? const {},
        );
      }

      state = state.copyWith(genreStats: genreStats, isLoading: false);
    } on Exception {
      state = state.copyWith(isLoading: false);
    }
  }
}
