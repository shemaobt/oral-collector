import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/invite/data/repositories/invite_repository.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

void main() {
  late _MockClient client;
  late InviteRepositoryImpl repo;

  setUp(() {
    client = _MockClient();
    repo = InviteRepositoryImpl(
      client: client,
      reporter: const NoopErrorReporter(),
    );
  });

  test('acceptInvite throws UnauthorizedException on 401', () async {
    when(
      () => client.post(any()),
    ).thenAnswer((_) async => http.Response('', 401));

    await expectLater(
      repo.acceptInvite('i-1'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('declineInvite throws UnauthorizedException on 401', () async {
    when(
      () => client.post(any()),
    ).thenAnswer((_) async => http.Response('', 401));

    await expectLater(
      repo.declineInvite('i-1'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('fetchMyInvites throws UnauthorizedException on 401', () async {
    when(
      () => client.get(any()),
    ).thenAnswer((_) async => http.Response('', 401));

    await expectLater(
      repo.fetchMyInvites(),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('acceptInvite completes on 204', () async {
    when(
      () => client.post(any()),
    ).thenAnswer((_) async => http.Response('', 204));

    await expectLater(repo.acceptInvite('i-1'), completes);
  });

  test('acceptInvite em 500 lança ServerException sem vazar o corpo', () async {
    when(
      () => client.post(any()),
    ).thenAnswer((_) async => http.Response('secret-body', 500));

    await expectLater(
      repo.acceptInvite('i-1'),
      throwsA(
        isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.code, 'code', 'server_500')
            .having(
              (e) => e.toString(),
              'toString',
              isNot(contains('secret-body')),
            ),
      ),
    );
  });

  test(
    'declineInvite em 500 lança ServerException sem vazar o corpo',
    () async {
      when(
        () => client.post(any()),
      ).thenAnswer((_) async => http.Response('secret-body', 500));

      await expectLater(
        repo.declineInvite('i-1'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'server_500')
              .having(
                (e) => e.toString(),
                'toString',
                isNot(contains('secret-body')),
              ),
        ),
      );
    },
  );
}
