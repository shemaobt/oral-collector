import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/network/response_decoder.dart';

void main() {
  group('decodeObject', () {
    test('returns the decoded object on a 2xx JSON object body', () {
      final result = decodeObject(http.Response('{"id":"x","n":1}', 200));

      expect(result['id'], 'x');
      expect(result['n'], 1);
    });

    test(
      'throws a catchable ParseException when the 2xx body is a JSON array',
      () {
        expect(
          () => decodeObject(http.Response('[1,2,3]', 200)),
          throwsA(isA<ParseException>()),
        );
      },
    );

    test('throws a FormatException when the 2xx body is not JSON', () {
      expect(
        () => decodeObject(http.Response('not-json', 200)),
        throwsA(isA<FormatException>()),
      );
    });

    test('maps a non-2xx status to a typed AppException', () {
      expect(
        () => decodeObject(http.Response('{}', 401)),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(
        () => decodeObject(http.Response('nope', 404)),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeObject(http.Response('boom', 500)),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('decodeList', () {
    test('returns the decoded list on a 2xx JSON array body', () {
      final result = decodeList(http.Response('[{"a":1},{"a":2}]', 200));

      expect(result, hasLength(2));
    });

    test(
      'throws a catchable ParseException when the 2xx body is a JSON object',
      () {
        expect(
          () => decodeList(http.Response('{"a":1}', 200)),
          throwsA(isA<ParseException>()),
        );
      },
    );

    test('maps a non-2xx status to a typed AppException', () {
      expect(
        () => decodeList(http.Response('err', 503)),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
