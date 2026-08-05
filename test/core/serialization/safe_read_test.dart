import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/serialization/safe_read.dart';

void main() {
  group('readString', () {
    test('lê uma String presente', () {
      expect(readString(<String, dynamic>{'id': 'abc'}, 'id'), 'abc');
    });

    test('chave ausente lança ParseException com o field', () {
      expect(
        () => readString(const <String, dynamic>{}, 'id'),
        throwsA(isA<ParseException>().having((e) => e.field, 'field', 'id')),
      );
    });

    test('valor null lança ParseException', () {
      expect(
        () => readString(<String, dynamic>{'id': null}, 'id'),
        throwsA(isA<ParseException>()),
      );
    });

    test('tipo errado lança ParseException com expected e cause', () {
      expect(
        () => readString(<String, dynamic>{'id': 42}, 'id'),
        throwsA(
          isA<ParseException>()
              .having((e) => e.field, 'field', 'id')
              .having((e) => e.expected, 'expected', 'String')
              .having((e) => e.cause, 'cause', 42),
        ),
      );
    });
  });

  group('readStringOrNull', () {
    test('lê uma String presente', () {
      expect(readStringOrNull(<String, dynamic>{'t': 'x'}, 't'), 'x');
    });

    test('chave ausente retorna null', () {
      expect(readStringOrNull(const <String, dynamic>{}, 't'), isNull);
    });

    test('valor null retorna null', () {
      expect(readStringOrNull(<String, dynamic>{'t': null}, 't'), isNull);
    });

    test('presente-mas-tipo-errado lança ParseException', () {
      expect(
        () => readStringOrNull(<String, dynamic>{'t': 42}, 't'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('readInt', () {
    test('lê um int', () {
      expect(readInt(<String, dynamic>{'n': 5}, 'n'), 5);
    });

    test('aceita num e trunca em direção a zero (3.9 -> 3, -3.9 -> -3)', () {
      expect(readInt(<String, dynamic>{'n': 3.9}, 'n'), 3);
      expect(readInt(<String, dynamic>{'n': -3.9}, 'n'), -3);
    });

    test('double não-finito lança ParseException (não UnsupportedError)', () {
      expect(
        () => readInt(<String, dynamic>{'n': double.infinity}, 'n'),
        throwsA(isA<ParseException>()),
      );
    });

    test('bool não é num: lança ParseException', () {
      expect(
        () => readInt(<String, dynamic>{'n': true}, 'n'),
        throwsA(
          isA<ParseException>().having((e) => e.expected, 'expected', 'int'),
        ),
      );
    });

    test('ausente lança ParseException', () {
      expect(
        () => readInt(const <String, dynamic>{}, 'n'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('readIntOrNull', () {
    test('ausente retorna null', () {
      expect(readIntOrNull(const <String, dynamic>{}, 'n'), isNull);
    });

    test('valor null retorna null', () {
      expect(readIntOrNull(<String, dynamic>{'n': null}, 'n'), isNull);
    });

    test('converte num? (5.0 -> 5)', () {
      expect(readIntOrNull(<String, dynamic>{'n': 5.0}, 'n'), 5);
    });

    test('double não-finito lança ParseException', () {
      expect(
        () => readIntOrNull(<String, dynamic>{'n': double.infinity}, 'n'),
        throwsA(isA<ParseException>()),
      );
    });

    test('presente-mas-tipo-errado lança ParseException', () {
      expect(
        () => readIntOrNull(<String, dynamic>{'n': 'x'}, 'n'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('readDouble', () {
    test('lê um double', () {
      expect(readDouble(<String, dynamic>{'d': 5.5}, 'd'), 5.5);
    });

    test('aceita int e converte (5 -> 5.0)', () {
      expect(readDouble(<String, dynamic>{'d': 5}, 'd'), 5.0);
    });

    test('ausente lança ParseException', () {
      expect(
        () => readDouble(const <String, dynamic>{}, 'd'),
        throwsA(isA<ParseException>()),
      );
    });

    test('tipo errado lança ParseException', () {
      expect(
        () => readDouble(<String, dynamic>{'d': 'x'}, 'd'),
        throwsA(
          isA<ParseException>().having((e) => e.expected, 'expected', 'double'),
        ),
      );
    });

    test('readDoubleOrNull ausente retorna null', () {
      expect(readDoubleOrNull(const <String, dynamic>{}, 'd'), isNull);
    });
  });

  group('readBool', () {
    test('lê um bool', () {
      expect(readBool(<String, dynamic>{'b': true}, 'b'), isTrue);
    });

    test('ausente lança ParseException', () {
      expect(
        () => readBool(const <String, dynamic>{}, 'b'),
        throwsA(isA<ParseException>()),
      );
    });

    test('String "true" não é bool: lança ParseException', () {
      expect(
        () => readBool(<String, dynamic>{'b': 'true'}, 'b'),
        throwsA(
          isA<ParseException>().having((e) => e.expected, 'expected', 'bool'),
        ),
      );
    });

    test('readBoolOrNull ausente retorna null', () {
      expect(readBoolOrNull(const <String, dynamic>{}, 'b'), isNull);
    });

    test('readBoolOrNull presente-mas-tipo-errado lança ParseException', () {
      expect(
        () => readBoolOrNull(<String, dynamic>{'b': 1}, 'b'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('readDate', () {
    test('parseia ISO-8601 com Z para o instante UTC', () {
      expect(
        readDate(<String, dynamic>{'d': '2024-01-15T10:30:45Z'}, 'd').toUtc(),
        DateTime.utc(2024, 1, 15, 10, 30, 45),
      );
    });

    test('parseia ISO-8601 com offset para o mesmo instante UTC', () {
      expect(
        readDate(<String, dynamic>{
          'd': '2024-01-15T12:30:45+02:00',
        }, 'd').toUtc(),
        DateTime.utc(2024, 1, 15, 10, 30, 45),
      );
    });

    test('valor não-String lança ParseException', () {
      expect(
        () => readDate(<String, dynamic>{'d': 123}, 'd'),
        throwsA(isA<ParseException>().having((e) => e.field, 'field', 'd')),
      );
    });

    test(
      'String não-parseável lança ParseException com cause FormatException',
      () {
        expect(
          () => readDate(<String, dynamic>{'d': 'not-a-date'}, 'd'),
          throwsA(
            isA<ParseException>().having(
              (e) => e.cause,
              'cause',
              isA<FormatException>(),
            ),
          ),
        );
      },
    );

    test('readDateOrNull ausente retorna null', () {
      expect(readDateOrNull(const <String, dynamic>{}, 'd'), isNull);
    });

    test('readDateOrNull valor null retorna null', () {
      expect(readDateOrNull(<String, dynamic>{'d': null}, 'd'), isNull);
    });

    test('readDateOrNull String ruim lança ParseException', () {
      expect(
        () => readDateOrNull(<String, dynamic>{'d': 'nope'}, 'd'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('readMap e encadeamento aninhado', () {
    test('lê um Map<String, dynamic>', () {
      final json = <String, dynamic>{
        'tokens': <String, dynamic>{'access_token': 'abc'},
      };
      expect(readMap(json, 'tokens'), <String, dynamic>{'access_token': 'abc'});
    });

    test('encadeamento: readString(readMap(...)) lê valor aninhado', () {
      final json = <String, dynamic>{
        'tokens': <String, dynamic>{'access_token': 'abc'},
      };
      expect(readString(readMap(json, 'tokens'), 'access_token'), 'abc');
    });

    test('chave ausente lança ParseException (converte NoSuchMethodError)', () {
      expect(
        () => readMap(const <String, dynamic>{}, 'tokens'),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'tokens'),
        ),
      );
    });

    test('valor não-map lança ParseException com expected', () {
      expect(
        () => readMap(<String, dynamic>{'tokens': 'oops'}, 'tokens'),
        throwsA(
          isA<ParseException>()
              .having((e) => e.field, 'field', 'tokens')
              .having((e) => e.expected, 'expected', 'Map<String, dynamic>'),
        ),
      );
    });

    test('readMapOrNull ausente retorna null', () {
      expect(readMapOrNull(const <String, dynamic>{}, 'tokens'), isNull);
    });

    test('readMapOrNull valor null retorna null', () {
      expect(
        readMapOrNull(<String, dynamic>{'tokens': null}, 'tokens'),
        isNull,
      );
    });
  });
}
