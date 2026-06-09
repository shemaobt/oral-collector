import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/data/project_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('read() returns null instead of crashing when a cached project has a '
      'wrong-typed field', () async {
    // `id` is an int, so Project.fromJson's `as String` throws a TypeError (an
    // Error, not an Exception) — the read must still degrade to a cache miss.
    SharedPreferences.setMockInitialValues({
      'cached_projects': '[{"id": 123, "name": "P", "language_id": "l-1"}]',
    });

    final result = await SharedPreferencesProjectCache().read();

    expect(result, isNull);
  });
}
