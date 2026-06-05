import 'dart:async' as async;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/error_boundary.dart';

Future<Never> _throwSocket() async {
  throw const SocketException('connection refused');
}

void main() {
  group('throwForStatus', () {
    test('401 -> UnauthorizedException', () {
      expect(() => throwForStatus(401), throwsA(isA<UnauthorizedException>()));
    });

    test('403 -> ForbiddenException', () {
      expect(() => throwForStatus(403), throwsA(isA<ForbiddenException>()));
    });

    test('409 -> ConflictException', () {
      expect(() => throwForStatus(409), throwsA(isA<ConflictException>()));
    });

    test('404 -> ValidationException com status e code derivado', () {
      expect(
        () => throwForStatus(404),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'client_404'),
        ),
      );
    });

    test('422 -> ValidationException', () {
      expect(() => throwForStatus(422), throwsA(isA<ValidationException>()));
    });

    test('500 -> ServerException com status e code derivado', () {
      expect(
        () => throwForStatus(500),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'server_500'),
        ),
      );
    });

    test('503 -> ServerException', () {
      expect(() => throwForStatus(503), throwsA(isA<ServerException>()));
    });

    test('status inesperado abaixo de 400 -> ServerException', () {
      expect(() => throwForStatus(204), throwsA(isA<ServerException>()));
    });
  });

  group('throwForResponse', () {
    test('extrai o traceId do header x-request-id', () {
      final response = http.Response(
        '',
        500,
        headers: {'x-request-id': 'req-42'},
      );

      expect(
        () => throwForResponse(response),
        throwsA(
          isA<ServerException>().having((e) => e.traceId, 'traceId', 'req-42'),
        ),
      );
    });

    test('sem header de trace, o traceId fica nulo', () {
      expect(
        () => throwForResponse(http.Response('', 500)),
        throwsA(
          isA<ServerException>().having((e) => e.traceId, 'traceId', isNull),
        ),
      );
    });
  });

  group('guard', () {
    test('retorna o valor quando o corpo tem sucesso', () async {
      expect(await guard(() async => 42), 42);
    });

    test(
      'SocketException -> NetworkException com cause sendo só o tipo',
      () async {
        await expectLater(
          guard(() async => throw const SocketException('refused')),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.cause,
              'cause',
              SocketException,
            ),
          ),
        );
      },
    );

    test(
      'TimeoutException do dart:async -> TimeoutException de domínio',
      () async {
        await expectLater(
          guard(() async => throw async.TimeoutException('slow')),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('AppException é repassada sem reembrulhar', () async {
      await expectLater(
        guard(() async => throw const ConflictException()),
        throwsA(isA<ConflictException>()),
      );
    });

    test('preserva o stack trace da origem ao mapear', () async {
      Object? caught;
      StackTrace? stack;

      try {
        await guard(_throwSocket);
      } catch (e, s) {
        caught = e;
        stack = s;
      }

      expect(caught, isA<NetworkException>());
      expect(stack, isNotNull);
      expect(stack.toString(), contains('_throwSocket'));
    });
  });
}
