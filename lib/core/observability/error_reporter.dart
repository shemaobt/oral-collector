import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../serialization/parse_list.dart';

/// Severity for reported errors/breadcrumbs. Vendor-neutral; maps cleanly onto
/// SentryLevel when a real adapter replaces the Noop default (ADR-0006).
enum ErrorLevel { fatal, error, warning, info, debug }

/// Pluggable crash/telemetry sink. The default is [NoopErrorReporter]; a Sentry
/// adapter is deferred (ADR-0006). Signatures mirror sentry_flutter so the
/// adapter is a thin pass-through. Implementations must keep the canonical
/// `level` defaults (reportError -> error, addBreadcrumb -> info) so callers
/// using the interface get the same behavior regardless of the wired adapter.
abstract interface class ErrorReporter {
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level,
  });

  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level,
    Map<String, Object?>? data,
  });

  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  });

  void clearUser();

  void setTag(String key, String value);
}

/// Default reporter: drops everything. Keeps release behavior unchanged until a
/// real adapter is wired in.
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {}

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

final errorReporterProvider = Provider<ErrorReporter>(
  (_) => const NoopErrorReporter(),
);

/// Routes Flutter's two global error hooks through [reporter], preserving the
/// existing presentError/debugPrint behavior. Set once, from main().
void installGlobalErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    reporter.reportError(
      details.exception,
      details.stack,
      level: ErrorLevel.fatal,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    reporter.reportError(error, stack, level: ErrorLevel.fatal);
    return true;
  };
}

/// Bridges a [parseList] skip into telemetry (ENG-166). Keeps the local
/// `developer.log` trace (visible in debug) and adds a warning-level report so
/// records dropped by the page policy become observable once a real adapter
/// replaces the Noop default. Pass the same `context` used in the parseList call.
///
/// The sink must not throw: `parseList` does not guard the `onSkip` call, so a
/// throwing reporter would propagate and blank the page it is meant to protect.
extension ParseSkipReporting on ErrorReporter {
  SkipCallback parseSkipSink({String? context}) => (error, stackTrace, index) {
    developer.log(
      'parseList[${context ?? '?'}]: skipped element #$index',
      name: 'parseList',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    reportError(
      error,
      stackTrace,
      level: ErrorLevel.warning,
      context: {if (context != null) 'parseContext': context, 'index': index},
    );
  };
}
