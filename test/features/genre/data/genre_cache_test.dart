import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/genre/data/genre_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesGenreCache cache;

  setUp(() {
    cache = SharedPreferencesGenreCache();
  });

  test(
    'read pula um genre malformado e retorna os válidos (não null)',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_genres': '[{"id":"g-1","name":"Folktale"},{"name":"sem id"}]',
      });

      final result = await cache.read();

      expect(result, isNotNull);
      expect(result!.map((g) => g.id).toList(), <String>['g-1']);
    },
  );

  test(
    'read com JSON corrompido retorna null (invalida o cache inteiro)',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_genres': 'not json at all',
      });

      final result = await cache.read();

      expect(result, isNull);
    },
  );
}
