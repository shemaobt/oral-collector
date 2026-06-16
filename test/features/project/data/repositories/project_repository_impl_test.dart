import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/project/data/repositories/project_repository_impl.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late ProjectRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockClient();
    repo = ProjectRepositoryImpl(
      client: client,
      reporter: const NoopErrorReporter(),
    );
  });

  group('getProject', () {
    test('returns the Project on a 200 object body', () async {
      when(() => client.get('/api/projects/p-1')).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': 'p-1', 'name': 'Proj', 'language_id': 'lang-1'}),
          200,
        ),
      );

      final project = await repo.getProject('p-1');

      expect(project.id, 'p-1');
      expect(project.name, 'Proj');
    });

    test(
      'throws a catchable ParseException when the body is not an object',
      () async {
        when(
          () => client.get('/api/projects/p-1'),
        ).thenAnswer((_) async => http.Response('[]', 200));

        await expectLater(
          repo.getProject('p-1'),
          throwsA(isA<ParseException>()),
        );
      },
    );

    test('throws UnauthorizedException on 401', () async {
      when(
        () => client.get(any()),
      ).thenAnswer((_) async => http.Response('', 401));

      await expectLater(
        repo.getProject('p-1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('getProjectStats', () {
    test('parses typed stats from a well-formed response', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'total_recordings': 5,
            'total_duration_seconds': 12.5,
            'total_storytellers': 3,
          }),
          200,
        ),
      );

      final stats = await repo.getProjectStats('p-1');

      expect(stats.totalRecordings, 5);
      expect(stats.totalDurationSeconds, 12.5);
      expect(stats.totalStorytellers, 3);
    });

    test('throws UnauthorizedException on 401', () async {
      when(
        () => client.get(any()),
      ).thenAnswer((_) async => http.Response('', 401));

      await expectLater(
        repo.getProjectStats('p-1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ServerException on 500', () async {
      when(
        () => client.get(any()),
      ).thenAnswer((_) async => http.Response('', 500));

      await expectLater(
        repo.getProjectStats('p-1'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createLanguage', () {
    test('throws a typed ServerException on a 500', () async {
      when(
        () => client.post('/api/languages', body: any(named: 'body')),
      ).thenAnswer((_) async => http.Response('upstream boom', 500));

      await expectLater(
        repo.createLanguage(name: 'EN', code: 'en'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('listProjects', () {
    test('returns the parsed list on a 200 array body', () async {
      when(() => client.get('/api/oc/projects')).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {'id': 'p-1', 'name': 'A', 'language_id': 'l-1'},
            {'id': 'p-2', 'name': 'B', 'language_id': 'l-1'},
          ]),
          200,
        ),
      );

      final projects = await repo.listProjects();

      expect(projects, hasLength(2));
      expect(projects.first.id, 'p-1');
    });

    test(
      'throws a catchable ParseException when the body is not a list',
      () async {
        when(
          () => client.get('/api/oc/projects'),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await expectLater(repo.listProjects(), throwsA(isA<ParseException>()));
      },
    );

    test('throws a typed ServerException on a 500', () async {
      when(
        () => client.get('/api/oc/projects'),
      ).thenAnswer((_) async => http.Response('upstream boom', 500));

      await expectLater(repo.listProjects(), throwsA(isA<ServerException>()));
    });
  });
}
