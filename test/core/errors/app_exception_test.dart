import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';

void main() {
  group('AppException.toString()', () {
    test('inclui tipo, code e status para diagnóstico', () {
      const e = ServerException(statusCode: 503);

      final s = e.toString();

      expect(s, contains('ServerException'));
      expect(s, contains('server'));
      expect(s, contains('503'));
    });

    test('redige o valor de cause, mantendo tipo e status', () {
      const secret = 'raw body token=abc123 email=user@example.com';
      const e = ServerException(statusCode: 500, cause: secret);

      final s = e.toString();

      expect(s, isNot(contains(secret)));
      expect(s, isNot(contains('token=abc123')));
      expect(s, contains('String'));
      expect(s, contains('500'));
    });

    test('inclui traceId quando presente', () {
      const e = ServerException(statusCode: 500, traceId: 'trace-xyz');

      expect(e.toString(), contains('trace-xyz'));
    });
  });

  group('contrato de captura', () {
    const leaves = <AppException>[
      NetworkException(),
      TimeoutException(),
      UnauthorizedException(),
      ForbiddenException(),
      ValidationException(),
      ServerException(statusCode: 500),
      ConflictException(),
      ParseException(field: 'x', expected: 'String'),
    ];

    test('toda folha continua capturável por on Exception', () {
      for (final e in leaves) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('status canônico das exceções de status fixo', () {
    test('UnauthorizedException carrega 401', () {
      expect(const UnauthorizedException().statusCode, 401);
    });

    test('ForbiddenException carrega 403', () {
      expect(const ForbiddenException().statusCode, 403);
    });

    test('ConflictException carrega 409', () {
      expect(const ConflictException().statusCode, 409);
    });
  });

  group('toString carrega o token que o fallback de UI reconhece', () {
    test('Unauthorized contém "unauthorized"', () {
      expect(
        const UnauthorizedException().toString().toLowerCase(),
        contains('unauthorized'),
      );
    });

    test('Forbidden contém "forbidden"', () {
      expect(
        const ForbiddenException().toString().toLowerCase(),
        contains('forbidden'),
      );
    });
  });

  group('ParseException', () {
    test('toString inclui field, expected e code', () {
      const e = ParseException(field: 'access_token', expected: 'String');

      final s = e.toString();

      expect(s, contains('access_token'));
      expect(s, contains('String'));
      expect(s, contains('parse'));
    });

    test('redige o valor de cause, mantendo o tipo', () {
      const secret = 'raw token=abc123 email=user@example.com';
      const e = ParseException(
        field: 'access_token',
        expected: 'String',
        cause: secret,
      );

      final s = e.toString();

      expect(s, isNot(contains(secret)));
      expect(s, isNot(contains('token=abc123')));
      expect(s, contains('String'));
    });
  });
}
