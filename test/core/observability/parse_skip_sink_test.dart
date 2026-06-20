import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/core/serialization/parse_list.dart';

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];
  final levels = <ErrorLevel>[];
  final contexts = <Map<String, Object?>?>[];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    errors.add(error);
    levels.add(level);
    contexts.add(context);
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level = ErrorLevel.info,
    Map<String, Object?>? data,
  }) {}

  @override
  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  }) {}

  @override
  void clearUser() {}

  @override
  void setTag(String key, String value) {}
}

// Force-casts like the real fromJson factories: a malformed element throws.
String _readId(Map<String, dynamic> json) => json['id'] as String;

void main() {
  group('ErrorReporter.parseSkipSink', () {
    test('reporta ao ErrorReporter um registro malformado pulado', () {
      final reporter = _RecordingReporter();

      final result = parseList(
        <Map<String, dynamic>>[
          {'id': 'a'},
          {'id': 42},
        ],
        _readId,
        context: 'listX',
        onSkip: reporter.parseSkipSink(context: 'listX'),
      );

      expect(result, <String>['a']);
      expect(reporter.errors, hasLength(1));
      expect(reporter.levels.single, ErrorLevel.warning);
    });

    test('reporta cada registro malformado com o índice no context', () {
      final reporter = _RecordingReporter();

      parseList(
        <Map<String, dynamic>>[
          {'id': 'a'},
          {'id': 1},
          {'id': 2},
        ],
        _readId,
        context: 'listX',
        onSkip: reporter.parseSkipSink(context: 'listX'),
      );

      expect(reporter.errors, hasLength(2));
      expect(reporter.contexts.map((c) => c?['index']).toList(), <Object?>[
        1,
        2,
      ]);
    });

    test('lista sem registros malformados não reporta nada', () {
      final reporter = _RecordingReporter();

      final result = parseList(
        <Map<String, dynamic>>[
          {'id': 'a'},
          {'id': 'b'},
        ],
        _readId,
        context: 'listX',
        onSkip: reporter.parseSkipSink(context: 'listX'),
      );

      expect(result, <String>['a', 'b']);
      expect(reporter.errors, isEmpty);
    });

    test('parseContext entra no context quando fornecido e some quando '
        'nulo', () {
      final withCtx = _RecordingReporter();
      parseList(
        <Map<String, dynamic>>[
          {'id': 1},
        ],
        _readId,
        context: 'listX',
        onSkip: withCtx.parseSkipSink(context: 'listX'),
      );
      expect(withCtx.contexts.single?['parseContext'], 'listX');

      final noCtx = _RecordingReporter();
      parseList(
        <Map<String, dynamic>>[
          {'id': 1},
        ],
        _readId,
        context: 'listX',
        onSkip: noCtx.parseSkipSink(),
      );
      expect(noCtx.contexts.single?.containsKey('parseContext'), isFalse);
    });
  });
}
