import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/data/project_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesProjectCache cache;

  setUp(() {
    cache = SharedPreferencesProjectCache();
  });

  test(
    'read pula um project malformado e retorna os válidos (não null)',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_projects':
            '[{"id":"p-1","name":"Proj","language_id":"l-1"},{"name":"sem id"}]',
        'cached_languages': '[{"id":"l-1","name":"English","code":"en"}]',
      });

      final result = await cache.read();

      expect(result, isNotNull);
      expect(result!.projects.map((p) => p.id).toList(), <String>['p-1']);
    },
  );

  test(
    'read com cached_projects ilegível (JSON inválido) retorna null',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_projects': 'not json at all',
      });

      expect(await cache.read(), isNull);
    },
  );

  test('read com cached_projects válido mas não-List retorna null', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'cached_projects': '{"id":"p-1"}',
    });

    expect(await cache.read(), isNull);
  });

  test('read pula uma language malformada preservando os projects', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'cached_projects': '[{"id":"p-1","name":"Proj","language_id":"l-1"}]',
      'cached_languages':
          '[{"id":"l-1","name":"English","code":"en"},{"id":"l-2"}]',
    });

    final result = await cache.read();

    expect(result, isNotNull);
    expect(result!.languages.map((l) => l.id).toList(), <String>['l-1']);
    expect(result.projects.map((p) => p.id).toList(), <String>['p-1']);
  });
}
