import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'error_reporter.dart';

/// Wires `package:logging` to the app's sinks. Call once from `main()` after the
/// [ErrorReporter] exists. Idempotent: it replaces any existing root listener so
/// repeated calls (and tests) never stack handlers on the shared `Logger.root`.
///
/// Every record goes to `dart:developer log()` (self-silencing in AOT/release).
/// Records at [Level.SEVERE]+ additionally forward to [reporter] so production
/// faults become observable once a real adapter replaces the Noop default.
void installLogging({required ErrorReporter reporter, Level? level}) {
  Logger.root.clearListeners();
  // Debug emits everything; release keeps warnings+ only.
  Logger.root.level = level ?? (kReleaseMode ? Level.WARNING : Level.ALL);
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      time: record.time,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    if (record.level >= Level.SEVERE) {
      // System boundary: the listener runs synchronously inside every log call,
      // so a throwing reporter would propagate into unrelated callers. Telemetry
      // is best-effort and must never crash the code that logged.
      try {
        reporter.reportError(
          record.error ?? record.message,
          record.stackTrace,
          level: _toErrorLevel(record.level),
        );
      } on Object {
        // Swallowed on purpose: see comment above.
      }
    }
  });
}

ErrorLevel _toErrorLevel(Level level) =>
    level >= Level.SHOUT ? ErrorLevel.fatal : ErrorLevel.error;
