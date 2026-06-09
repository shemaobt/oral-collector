import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/data/genre_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('read() returns null instead of crashing when a cached genre has a '
      'wrong-typed field', () async {
    // `id` is an int, so Genre.fromJson's `as String` throws a TypeError (an
    // Error, not an Exception) — the read must still degrade to a cache miss.
    SharedPreferences.setMockInitialValues({
      'cached_genres': '[{"id": 123, "name": "Tales"}]',
    });

    final result = await SharedPreferencesGenreCache().read();

    expect(result, isNull);
  });
}
