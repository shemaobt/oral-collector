# Noridoc: Sync Data Services

Path: @/lib/features/sync/data/services

### Overview

- The mechanics of getting pending recordings off the device: the upload
  transport, the Android foreground service that keeps uploads alive while
  the app is minimized, the iOS Live Activity, and the coordinator that
  pauses uploads while a recording is in progress.
- The presentation layer ([/lib/features/sync/presentation/notifiers/sync_notifier.dart](../../presentation/notifiers/sync_notifier.dart))
  orchestrates these services and owns sync UI state; this folder owns the
  side effects (network, notifications, OS process lifecycle).
- Android keeps uploads running in the background via a foreground service;
  iOS relies on `background_downloader`. Both resume from the saved GCS
  offset on the next launch, so a swipe-away is safe.

### How it fits into the larger codebase

- Pending work comes from the recording feature: services here read
  `localRecordingRepositoryProvider`
  ([/lib/features/recording/data/repositories/local_recording_repository.dart](../../../recording/data/repositories/local_recording_repository.dart))
  to enumerate `getPendingUploads` and to flip rows
  `uploading` / `uploaded` / `failed`. The actual queue walk lives in the
  `SyncEngine` ([/lib/features/sync/domain/repositories/sync_engine.dart](../../domain/repositories/sync_engine.dart)).
- `UploadForegroundService` shares the single Android foreground service
  with recording. It does not call the plugin directly for lifecycle; it
  goes through [/lib/core/platform/foreground_service_arbiter.dart](../../../../core/platform/foreground_service_arbiter.dart)
  as owner `upload`. The recording side is the other owner via
  [/lib/features/recording/data/services/recording_foreground_service.dart](../../../recording/data/services/recording_foreground_service.dart).
- `BackgroundUploadCoordinator` listens to the recording session state
  ([/lib/features/recording/presentation/notifiers/recording_session_notifier.dart](../../../recording/presentation/notifiers/recording_session_notifier.dart))
  and, when a recording starts, cancels in-flight downloads and releases the
  upload foreground service; when recording ends it resumes downloads and
  re-triggers `SyncNotifier.processQueue`.
- `providers.dart` ([../providers.dart](../providers.dart)) exposes
  `uploadForegroundServiceProvider`, `uploadDownloaderProvider`, and
  `syncEngineProvider` consumed by the notifier and coordinator.

### Core Implementation

- `UploadForegroundService.start` calls `FlutterForegroundTask.init` before
  every start because recording and upload use different notification
  channels (`upload_foreground` vs `recording_foreground`); the active
  channel must be re-configured per start since the two features share one
  service. `start` maps to `arbiter.takeOver(owner: upload, ...)`, `stop`
  maps to `arbiter.release(owner: upload, ...)`, and `updateProgress` is
  guarded by `arbiter.isOwner(upload)` so progress text only writes to the
  notification while upload owns it. The l10n title resolver runs only after
  the Android platform guard.
- `UploadProgressVisualizer` pushes per-recording progress onto the
  foreground-service notification via `updateProgress` (Android) and onto
  the iOS Live Activity. Because `updateProgress` is owner-gated, a progress
  tick that lands after recording has taken over the service is silently
  dropped instead of overwriting the recording notification.
- `BackgroundUploadCoordinator._suspendForRecording` cancels downloads then
  calls `uploadForegroundService.stop()`. Since that stop is owner-aware via
  the arbiter, it is safe in any ordering relative to recording taking over:
  if recording already owns the service, the upload release no-ops rather
  than killing the recording notification.
- The transport itself (`resumable_upload_service.dart`,
  `upload_downloader.dart`) validates CRC32C and resumes from the saved GCS
  offset; the foreground service / Live Activity are lifecycle and UI
  concerns layered on top of it.
- The server returns the GCS target out-of-band (`upload_url` for single-PUT,
  `session_uri` for resumable), so the transport re-checks its scheme at the
  server→app boundary before any PUT, using the `isHttpsUrl` predicate from
  [/lib/core/config/url_policy.dart](../../../../core/config/url_policy.dart).
  This is the only place the presigned URL is scheme-validated — it never flows
  through `AuthenticatedClient.baseUrl`. See "Things to Know".

### Things to Know

- **One foreground service, two owners, two service ids.** The plugin allows
  a single foreground service; recording (`serviceId 1002`, `microphone`)
  and upload (`serviceId 1003`, `dataSync`) hand it back and forth through
  the arbiter. The native service is declared once with both types in
  [/android/app/src/main/AndroidManifest.xml](../../../../../android/app/src/main/AndroidManifest.xml).
- **`stopWithTask=true`.** A swipe-away ends the service while the queue is
  mid-upload; this is intentional because the queue resumes from the saved
  offset on next launch. Do not assume the notification implies an
  uninterruptible upload.
- **Notification lifetime is a reentrancy hazard at the caller.** The upload
  FGS is started/stopped around the engine call inside
  `SyncNotifier._runQueue`. `processQueue` holds a shared `_isProcessing`
  upload guard — also taken by `syncOne` — so the two upload entry points are
  mutually exclusive
  ([/lib/features/sync/presentation/notifiers/sync_notifier.dart](../../presentation/notifiers/sync_notifier.dart)).
  Without that guard a second concurrent `processQueue` (e.g. app resume →
  recordings-list refresh → `processQueue`) short-circuited on the engine's
  own guard but still ran its `finally`, stopping the foreground service
  while the first upload kept running — the notification vanished mid-upload.
  The same guard now also blocks a `syncOne` (e.g. reset-and-retry) from
  starting underneath an active queue, so the FGS is never stopped out from
  under an in-flight upload.

- **A non-https presigned URL fails closed, it does not crash the upload.**
  Both single-PUT paths reject the server's `upload_url` by returning
  `ResumableUploadResult(success: false)` (so the queue marks the row failed
  and retries later), and `_requestResumableSession` rejects a non-https
  `session_uri` by logging and returning `null`, which surfaces as a failed
  session to its callers. This is the transport half of the app-wide
  no-cleartext-PUT invariant whose policy and rationale live in
  [/lib/core/network/docs.md](../../../../core/network/docs.md); the
  config/contract half throws instead.

Created and maintained by Nori.
