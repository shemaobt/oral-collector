import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/genre/data/genre_cache.dart';
import 'package:oral_collector/features/genre/data/providers.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/domain/repositories/genre_repository.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';

class MockGenreRepository extends Mock implements GenreRepository {}

/// Cache fake whose [read] can be gated on a [Completer], forcing the
/// interleaving (fetch completes before hydration) that the real static
/// SharedPreferences singleton makes unreachable. [read] returns a fixed
/// [cached] snapshot — unaffected by [write] — so a late hydration genuinely
/// carries the stale data the guard must reject.
class FakeGenreCache implements GenreCache {
  FakeGenreCache({this.cached, this.gateRead = false});

  final List<Genre>? cached;
  final bool gateRead;
  final Completer<void> readGate = Completer<void>();

  @override
  Future<List<Genre>?> read() async {
    if (gateRead) await readGate.future;
    return cached;
  }

  @override
  Future<void> write(List<Genre> genres) async {}
}

Genre _genre(String id) => Genre(id: id, name: 'name-$id');

void main() {
  late MockGenreRepository repo;

  setUp(() {
    repo = MockGenreRepository();
  });

  ProviderContainer makeContainer(GenreCache cache) {
    final container = ProviderContainer(
      overrides: [
        genreRepositoryProvider.overrideWithValue(repo),
        genreCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'a completed fetch is not overwritten by a late stale-cache hydration',
    () async {
      final cache = FakeGenreCache(
        cached: [_genre('stale-1'), _genre('stale-2')],
        gateRead: true,
      );
      final serverGenres = [_genre('srv-1'), _genre('srv-2'), _genre('srv-3')];
      when(() => repo.listGenres()).thenAnswer((_) async => serverGenres);

      final container = makeContainer(cache);
      // build() fires _hydrateFromCache, which parks inside the gated read().
      final notifier = container.read(genreNotifierProvider.notifier);

      await notifier.fetchGenres(); // completes: server data + lastFetched

      var state = container.read(genreNotifierProvider);
      expect(state.genres.map((g) => g.id).toList(), [
        'srv-1',
        'srv-2',
        'srv-3',
      ]);
      expect(state.lastFetched, isNotNull);

      cache.readGate.complete(); // release the late hydration
      await Future<void>.delayed(Duration.zero);

      state = container.read(genreNotifierProvider);
      expect(
        state.genres.map((g) => g.id).toList(),
        ['srv-1', 'srv-2', 'srv-3'],
        reason:
            'stale cache must not overwrite server data after a completed fetch',
      );
    },
  );

  test('cached genres hydrate state when no fetch occurs', () async {
    final cache = FakeGenreCache(
      cached: [_genre('cached-1'), _genre('cached-2')],
    );
    final container = makeContainer(cache);

    container.read(genreNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(genreNotifierProvider);
    expect(state.genres.map((g) => g.id).toList(), ['cached-1', 'cached-2']);
    expect(state.lastFetched, isNull);
  });

  test('empty cache leaves state empty', () async {
    final cache = FakeGenreCache(cached: null);
    final container = makeContainer(cache);

    container.read(genreNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(genreNotifierProvider);
    expect(state.genres, isEmpty);
    expect(state.lastFetched, isNull);
  });
}
