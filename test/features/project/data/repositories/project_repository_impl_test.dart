import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/project/data/repositories/project_repository_impl.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late ProjectRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = ProjectRepositoryImpl(client: client);
  });

  test('getProject throws UnauthorizedException on 401', () async {
    when(
      () => client.get(any()),
    ).thenAnswer((_) async => http.Response('', 401));

    await expectLater(
      repo.getProject('p-1'),
      throwsA(isA<UnauthorizedException>()),
    );
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
}
