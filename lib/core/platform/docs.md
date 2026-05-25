# Noridoc: Core Platform

Path: @/lib/core/platform

### Overview

- Platform abstraction layer: each capability that differs between native
  and web ships as a `*_native.dart` / `*_web.dart` pair behind a thin
  conditional-import facade (`disk_space.dart`, `file_ops.dart`,
  `ffmpeg_ops.dart`, `file_source.dart`, `web_file_picker.dart`), so feature
  code imports one symbol and the right implementation is linked per target.
- Also hosts cross-feature process-state primitives that are not a
  native/web split: `recording_active_flag.dart` and
  [./foreground_service_arbiter.dart](foreground_service_arbiter.dart).
- Consumed broadly by the recording and sync features for file IO, disk
  reporting, FFmpeg, file import, and (Android) the shared foreground
  service.

### How it fits into the larger codebase

- The conditional-import facades are the only thing feature code should
  import; they re-export the native or web variant via Dart's
  `if (dart.library.html)` mechanism. Callers never reference the `_native`
  / `_web` files directly.
- `ForegroundServiceArbiter` is the single source of truth for who owns the
  one Android foreground service that the `flutter_foreground_task` plugin
  exposes. The plugin allows exactly one foreground service in the process,
  but two features want it: recording (declared service id `1002`, type
  `microphone`) and upload (service id `1003`, type `dataSync`). Both
  service types are declared on the single native `ForegroundService` in
  [/android/app/src/main/AndroidManifest.xml](../../../android/app/src/main/AndroidManifest.xml)
  (with `stopWithTask=true`).
- Two callers go through the arbiter:
  - [/lib/features/recording/data/services/recording_foreground_service.dart](../../features/recording/data/services/recording_foreground_service.dart)
    (owner `recording`).
  - [/lib/features/sync/data/services/upload_foreground_service.dart](../../features/sync/data/services/upload_foreground_service.dart)
    (owner `upload`).
- The arbiter does not import `flutter_foreground_task`. Both callers inject
  the plugin's `isRunningService` / `startService` / `stopService` as
  callbacks, which keeps the ownership logic unit-testable without the
  native singleton (see
  [/test/core/platform/foreground_service_arbiter_test.dart](../../../test/core/platform/foreground_service_arbiter_test.dart)).

### Core Implementation

- `ForegroundServiceArbiter` is all static state: a single `_owner`
  (`none` / `recording` / `upload`) plus a `_queue` mutex.
- `takeOver(owner, isRunning, stop, start)` is the hand-off primitive: it
  stops whatever is currently running (awaiting until it actually stops),
  then starts the new service, then records the new owner. A recording that
  starts over an active upload therefore becomes a single deterministic
  stop-then-start instead of two independent objects racing
  `startService` / `stopService`.
- `release(owner, isRunning, stop)` stops the service only if `owner` still
  matches `_owner`; otherwise it is a no-op. This is what lets one feature's
  stop never tear down the other feature's notification after a hand-off.
- `isOwner(owner)` is the guard the callers use for `update` /
  `updateProgress` and for their own `isRunning` getters, so a feature only
  touches the notification while it owns the service.
- `_serialized` chains every `takeOver` / `release` onto `_queue` so they
  run one at a time and never interleave.

### Things to Know

- **Serialization closes a TOCTOU window.** `release` re-checks ownership
  and then awaits `isRunning` / `stop`. If a hand-off could run during those
  awaits, a stale release could stop the service the hand-off just claimed.
  The `_queue` mutex forces a release queued during a take-over to run
  strictly after it, so it sees the new owner and no-ops. The gated test in
  [/test/core/platform/foreground_service_arbiter_test.dart](../../../test/core/platform/foreground_service_arbiter_test.dart)
  pins this ordering.
- **`_owner` is process-global static state.** It mirrors the single native
  service, so there is intentionally one arbiter for the whole app, not one
  per Riverpod scope. `resetForTest` clears `_owner` and `_queue` between
  tests.
- **The arbiter only tracks ownership; the plugin tracks liveness.** Callers
  pass `FlutterForegroundTask.isRunningService` as `isRunning`, so the
  arbiter never assumes the service is up just because it recorded an owner
  — a swipe-away (`stopWithTask`) that kills the service out from under the
  arbiter is reconciled on the next `takeOver`.

Created and maintained by Nori.
