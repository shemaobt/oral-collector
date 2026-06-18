import 'dart:async';

/// Runs an async action with at-most-one outstanding call: while a run is in
/// flight, further [run] calls are dropped (coalesced). Errors are routed to
/// [onError] instead of becoming unhandled async errors.
///
/// Used to rate-limit fire-and-forget platform updates (foreground-service
/// notification, iOS Live Activity) driven by the 1 Hz recording ticker, so a
/// platform call slower than the tick interval can't stack.
class SingleFlightRunner {
  SingleFlightRunner(this._action, {required this.onError});

  final Future<void> Function() _action;
  final void Function(Object error, StackTrace stackTrace) onError;
  bool _inFlight = false;

  void run() {
    if (_inFlight) return;
    _inFlight = true;
    unawaited(_runOnce());
  }

  Future<void> _runOnce() async {
    try {
      await _action();
    } catch (e, st) {
      onError(e, st);
    } finally {
      _inFlight = false;
    }
  }
}
