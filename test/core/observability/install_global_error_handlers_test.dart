import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';

class _MockReporter extends Mock implements ErrorReporter {}

void main() {
  late FlutterExceptionHandler? originalFlutterOnError;
  late ErrorCallback? originalPlatformOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  });

  test('FlutterError.onError encaminha exception e stack como fatal', () {
    final reporter = _MockReporter();
    installGlobalErrorHandlers(reporter);

    final ex = Exception('widget boom');
    final st = StackTrace.current;
    FlutterError.onError!(FlutterErrorDetails(exception: ex, stack: st));

    verify(
      () => reporter.reportError(ex, st, level: ErrorLevel.fatal),
    ).called(1);
  });

  test('FlutterError.onError com stack nulo ainda encaminha', () {
    final reporter = _MockReporter();
    installGlobalErrorHandlers(reporter);

    final ex = Exception('no stack');
    FlutterError.onError!(FlutterErrorDetails(exception: ex));

    verify(
      () => reporter.reportError(ex, null, level: ErrorLevel.fatal),
    ).called(1);
  });

  test('PlatformDispatcher.onError encaminha e retorna true', () {
    final reporter = _MockReporter();
    installGlobalErrorHandlers(reporter);

    final ex = Exception('async boom');
    final st = StackTrace.current;
    final handled = PlatformDispatcher.instance.onError!(ex, st);

    expect(handled, isTrue);
    verify(
      () => reporter.reportError(ex, st, level: ErrorLevel.fatal),
    ).called(1);
  });
}
