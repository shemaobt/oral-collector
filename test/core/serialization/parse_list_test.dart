import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/serialization/parse_list.dart';

// Force-casts exactly like the real fromJson factories: a malformed element
// throws a TypeError (an Error, not an Exception).
String _readId(Map<String, dynamic> json) => json['id'] as String;

class _SkipSpy {
  final indices = <int>[];
  final errors = <Object>[];

  void call(Object error, StackTrace stackTrace, int index) {
    errors.add(error);
    indices.add(index);
  }
}

void main() {
  group('parseList', () {
    test('mapeia todos os elementos válidos', () {
      final spy = _SkipSpy();
      final result = parseList(
        <Map<String, dynamic>>[
          {'id': 'a'},
          {'id': 'b'},
        ],
        _readId,
        onSkip: spy.call,
      );
      expect(result, <String>['a', 'b']);
      expect(spy.indices, isEmpty);
    });

    test(
      'pula e reporta (via onSkip) 1 elemento malformado no meio, retorna os bons',
      () {
        final spy = _SkipSpy();
        final result = parseList(
          <Map<String, dynamic>>[
            {'id': 'a'},
            {'id': 42},
            {'id': 'b'},
          ],
          _readId,
          onSkip: spy.call,
        );
        expect(result, <String>['a', 'b']);
        expect(spy.indices, <int>[1]);
      },
    );

    test(
      'captura Error de force-cast e pula o elemento (não só Exception)',
      () {
        final spy = _SkipSpy();
        final result = parseList(
          <Map<String, dynamic>>[
            {'id': 42},
          ],
          _readId,
          onSkip: spy.call,
        );
        expect(result, isEmpty);
        expect(spy.indices, <int>[0]);
        expect(spy.errors.single, isA<Error>());
      },
    );

    test('captura ParseException (forward-compat pós-migração)', () {
      final spy = _SkipSpy();
      final result = parseList(
        <Map<String, dynamic>>[
          {'id': 'x'},
        ],
        (_) => throw const ParseException(field: 'id', expected: 'String'),
        onSkip: spy.call,
      );
      expect(result, isEmpty);
      expect(spy.indices, <int>[0]);
    });

    test('todos malformados retorna lista vazia e reporta cada um', () {
      final spy = _SkipSpy();
      final result = parseList(
        <Map<String, dynamic>>[
          {'id': 1},
          {'id': 2},
        ],
        _readId,
        onSkip: spy.call,
      );
      expect(result, isEmpty);
      expect(spy.indices, <int>[0, 1]);
    });

    test('lista vazia retorna lista vazia, onSkip nunca chamado', () {
      final spy = _SkipSpy();
      final result = parseList(
        <Map<String, dynamic>>[],
        _readId,
        onSkip: spy.call,
      );
      expect(result, isEmpty);
      expect(spy.indices, isEmpty);
    });

    test('entrada não-List lança ParseException com expected "List"', () {
      final spy = _SkipSpy();
      for (final bad in <Object?>[<String, dynamic>{}, 'x', 42, null]) {
        expect(
          () => parseList(bad, _readId, onSkip: spy.call),
          throwsA(
            isA<ParseException>().having((e) => e.expected, 'expected', 'List'),
          ),
        );
      }
      expect(spy.indices, isEmpty);
    });

    test('context vira o field do ParseException no fail-fast de não-List', () {
      expect(
        () => parseList('x', _readId, context: 'listGenres'),
        throwsA(
          isA<ParseException>().having((e) => e.field, 'field', 'listGenres'),
        ),
      );
    });

    test('elemento não-Map é pulado, não derruba a lista', () {
      final spy = _SkipSpy();
      final result = parseList(
        <Object?>[
          42,
          <String, dynamic>{'id': 'b'},
        ],
        _readId,
        onSkip: spy.call,
      );
      expect(result, <String>['b']);
      expect(spy.indices, <int>[0]);
    });

    test('onSkip recebe o erro lançado e o índice correto', () {
      final spy = _SkipSpy();
      final boom = Exception('boom');
      parseList(
        <Map<String, dynamic>>[
          {'id': 'a'},
          {'id': 'b'},
        ],
        (json) {
          if (json['id'] == 'b') throw boom;
          return json['id'] as String;
        },
        onSkip: spy.call,
      );
      expect(spy.indices, <int>[1]);
      expect(spy.errors.single, same(boom));
    });

    test('sem onSkip não lança e retorna os bons (sink default)', () {
      final result = parseList(<Map<String, dynamic>>[
        {'id': 'a'},
        {'id': 42},
      ], _readId);
      expect(result, <String>['a']);
    });
  });
}
