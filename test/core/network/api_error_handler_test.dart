import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/api_error_handler.dart';

void main() {
  group('guardResponse', () {
    test('401 lança UnauthorizedException', () {
      expect(
        () => guardResponse(http.Response('', 401)),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 lança ForbiddenException', () {
      expect(
        () => guardResponse(http.Response('', 403)),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('apenas 401/403 lançam; sucesso e outros erros passam', () {
      for (final status in [200, 201, 204, 404, 409, 422, 500]) {
        expect(() => guardResponse(http.Response('', status)), returnsNormally);
      }
    });

    test('propaga o traceId do header no 401', () {
      expect(
        () => guardResponse(
          http.Response('', 401, headers: {'x-request-id': 'abc'}),
        ),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.traceId,
            'traceId',
            'abc',
          ),
        ),
      );
    });
  });
}
