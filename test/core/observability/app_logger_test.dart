import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:oral_collector/core/observability/app_logger.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];
  final levels = <ErrorLevel>[];
  final stacks = <StackTrace?>[];

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
    stacks.add(stackTrace);
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

class _ThrowingReporter implements ErrorReporter {
  int calls = 0;

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    calls++;
    throw StateError('reporter down');
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

void main() {
  tearDown(() {
    Logger.root.clearListeners();
    Logger.root.level = Level.INFO;
  });

  group('installLogging encaminha ao ErrorReporter', () {
    test('um log severe encaminha como ErrorLevel.error com o erro e o '
        'stack', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.ALL);

      final error = Exception('boom');
      final stack = StackTrace.current;
      Logger('TestComp').severe('falhou', error, stack);

      expect(reporter.errors.single, error);
      expect(reporter.levels.single, ErrorLevel.error);
      expect(reporter.stacks.single, stack);
    });

    test('um log shout encaminha como ErrorLevel.fatal', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.ALL);

      Logger('TestComp').shout('crash', Exception('x'), StackTrace.current);

      expect(reporter.levels.single, ErrorLevel.fatal);
    });

    test('um log severe sem objeto de erro encaminha a mensagem como erro', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.ALL);

      Logger('TestComp').severe('só mensagem');

      expect(reporter.errors.single, 'só mensagem');
      expect(reporter.levels.single, ErrorLevel.error);
      expect(reporter.stacks.single, isNull);
    });

    test('logs info e warning não encaminham ao reporter', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.ALL);

      Logger('TestComp').info('apenas diagnóstico');
      Logger('TestComp').warning('aviso não-fatal');

      expect(reporter.errors, isEmpty);
    });

    test('o nível configurado descarta registros abaixo do limiar', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.SEVERE);

      Logger('TestComp').info('descartado');
      Logger('TestComp').warning('descartado');
      expect(reporter.errors, isEmpty);

      Logger('TestComp').severe('passa', Exception('y'), StackTrace.current);
      expect(reporter.errors, hasLength(1));
    });

    test('um reporter que lança não propaga para fora da chamada de log', () {
      final reporter = _ThrowingReporter();
      installLogging(reporter: reporter, level: Level.ALL);

      expect(
        () => Logger(
          'TestComp',
        ).severe('boom', Exception('z'), StackTrace.current),
        returnsNormally,
      );
      expect(reporter.calls, 1);
    });

    test('installLogging é idempotente: chamadas repetidas não empilham '
        'listeners', () {
      final reporter = _RecordingReporter();
      installLogging(reporter: reporter, level: Level.ALL);
      installLogging(reporter: reporter, level: Level.ALL);

      Logger('TestComp').severe('boom', Exception('x'), StackTrace.current);

      expect(reporter.errors, hasLength(1));
    });
  });
}
