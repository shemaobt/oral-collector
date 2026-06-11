/// Runs [action] over [items] with at most [limit] actions in flight at once,
/// preserving input order in the returned list. [limit] must be >= 1.
///
/// Unlike `Future.wait(items.map(action))`, this caps concurrency, so fanning
/// out over a large collection cannot launch an unbounded number of operations
/// (e.g. simultaneous network requests) at the same time.
Future<List<T>> mapBounded<S, T>(
  Iterable<S> items,
  int limit,
  Future<T> Function(S item) action,
) async {
  assert(limit >= 1, 'limit must be >= 1');
  final list = items.toList();
  final results = List<T?>.filled(list.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= list.length) return;
      results[index] = await action(list[index]);
    }
  }

  final workerCount = limit < list.length ? limit : list.length;
  await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
  return [for (final r in results) r as T];
}
