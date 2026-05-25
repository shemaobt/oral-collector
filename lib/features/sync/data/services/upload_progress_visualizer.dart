import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/platform/recording_active_flag.dart';
import '../../../../l10n/app_localizations.dart';
import '../../presentation/notifiers/sync_notifier.dart';
import '../../presentation/notifiers/sync_state.dart';
import '../providers.dart';
import 'upload_foreground_service.dart';
import 'upload_live_activity.dart';

typedef LocalizationsResolver = Future<AppLocalizations> Function();

Future<AppLocalizations> _defaultLocalizationsResolver() async {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return AppLocalizations.delegate.load(locale);
}

class UploadProgressVisualizer {
  UploadProgressVisualizer({
    UploadLiveActivity? liveActivity,
    UploadForegroundService? uploadForegroundService,
    RecordingActiveFlag? recordingFlag,
    LocalizationsResolver? localizationsResolver,
  }) : _liveActivity = liveActivity ?? UploadLiveActivity.instance,
       _uploadForegroundService =
           uploadForegroundService ?? UploadForegroundService(),
       _recordingFlag = recordingFlag ?? const RecordingActiveFlag(),
       _resolveLocalizations =
           localizationsResolver ?? _defaultLocalizationsResolver;

  final UploadLiveActivity _liveActivity;
  // On Android the upload notification IS the foreground service's ongoing
  // notification (the service keeps the process alive while minimized), so we
  // update that one rather than showing a separate progress notification.
  final UploadForegroundService _uploadForegroundService;
  final RecordingActiveFlag _recordingFlag;
  final LocalizationsResolver _resolveLocalizations;
  String? _activeRecordingId;
  // Track the last shown integer-percent so we don't rebuild the Android
  // notification view on every minor float update (the upload coordinator
  // can fire dozens of progress events per chunk).
  int _lastShownPercent = -1;

  String _androidBody(String fileName, int progressPercent) =>
      '$fileName • $progressPercent%';

  Future<void> onStateChanged(SyncState? previous, SyncState next) async {
    if (kIsWeb) return;

    final previousId = previous?.uploadingId;
    final nextId = next.uploadingId;
    final fileName = next.currentFileName ?? 'Recording';

    if (previousId == null && nextId != null) {
      // §1 invariant: if a recording is active, don't surface upload UI at
      // all. The upload loop itself short-circuits on the same flag, but the
      // visualizer is wired independently — a stray sync state event during
      // the recording-start transition could otherwise pop a notification
      // on top of the recording one.
      if (await _recordingFlag.read()) return;

      _activeRecordingId = nextId;
      _lastShownPercent = next.syncProgress;
      final l10n = await _resolveLocalizations();
      if (Platform.isIOS) {
        await _liveActivity.start(
          activityId: nextId,
          fileName: fileName,
          progressPercent: next.syncProgress,
          localizedUploadingStatus: l10n.liveActivity_uploadingStatus,
          localizedUploadingRecordingTitle:
              l10n.upload_inProgressNotificationTitle,
        );
      } else if (Platform.isAndroid) {
        await _uploadForegroundService.updateProgress(
          title: l10n.upload_inProgressNotificationTitle,
          body: _androidBody(fileName, next.syncProgress),
        );
      }
      return;
    }

    if (previousId != null && nextId == null) {
      _activeRecordingId = null;
      _lastShownPercent = -1;
      if (Platform.isIOS) {
        await _liveActivity.stop();
      }
      // Android: the foreground service (and its notification) is stopped by
      // SyncNotifier when the queue finishes — nothing to clear here.
      return;
    }

    if (previousId != null && nextId != null && previousId != nextId) {
      _activeRecordingId = nextId;
      _lastShownPercent = next.syncProgress;
      final l10n = await _resolveLocalizations();
      if (Platform.isIOS) {
        await _liveActivity.stop();
        await _liveActivity.start(
          activityId: nextId,
          fileName: fileName,
          progressPercent: next.syncProgress,
          localizedUploadingStatus: l10n.liveActivity_uploadingStatus,
          localizedUploadingRecordingTitle:
              l10n.upload_inProgressNotificationTitle,
        );
      } else if (Platform.isAndroid) {
        await _uploadForegroundService.updateProgress(
          title: l10n.upload_inProgressNotificationTitle,
          body: _androidBody(fileName, next.syncProgress),
        );
      }
      return;
    }

    if (nextId != null &&
        nextId == _activeRecordingId &&
        previous?.syncProgress != next.syncProgress) {
      if (Platform.isIOS) {
        // iOS Live Activity has its own per-update budget; let it through.
        await _liveActivity.update(progressPercent: next.syncProgress);
      } else if (Platform.isAndroid) {
        // Skip if the integer-percent hasn't moved — the foreground-service
        // notification view still rebuilds otherwise.
        if (next.syncProgress == _lastShownPercent) return;
        _lastShownPercent = next.syncProgress;
        final l10n = await _resolveLocalizations();
        await _uploadForegroundService.updateProgress(
          title: l10n.upload_inProgressNotificationTitle,
          body: _androidBody(fileName, next.syncProgress),
        );
      }
    }
  }
}

extension on UploadProgressVisualizer {
  Future<void> retryForegroundLiveActivity(SyncState current) async {
    if (kIsWeb || !Platform.isIOS) return;
    final id = current.uploadingId;
    if (id == null) return;
    if (_liveActivity.hasActivity) return;
    final l10n = await _resolveLocalizations();
    await _liveActivity.start(
      activityId: id,
      fileName: current.currentFileName ?? 'Recording',
      progressPercent: current.syncProgress,
      localizedUploadingStatus: l10n.liveActivity_uploadingStatus,
      localizedUploadingRecordingTitle: l10n.upload_inProgressNotificationTitle,
    );
  }
}

final uploadProgressVisualizerProvider = Provider<UploadProgressVisualizer>((
  ref,
) {
  return UploadProgressVisualizer(
    // Share the same foreground-service instance SyncNotifier starts/stops, so
    // its running state is consistent when we update the notification.
    uploadForegroundService: ref.read(uploadForegroundServiceProvider),
    localizationsResolver: () async {
      // Prefer the explicit user locale; fall back to the OS locale.
      final Locale locale =
          ref.read(localeProvider) ??
          WidgetsBinding.instance.platformDispatcher.locale;
      return AppLocalizations.delegate.load(locale);
    },
  );
});

final uploadProgressVisualizerListenerProvider = Provider<void>((ref) {
  final visualizer = ref.read(uploadProgressVisualizerProvider);
  ref.listen<SyncState>(syncNotifierProvider, (previous, next) {
    unawaited(visualizer.onStateChanged(previous, next));
  });

  final lifecycleListener = AppLifecycleListener(
    onResume: () {
      final current = ref.read(syncNotifierProvider);
      unawaited(visualizer.retryForegroundLiveActivity(current));
    },
  );
  ref.onDispose(lifecycleListener.dispose);
});
