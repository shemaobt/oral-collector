import 'dart:async';
import 'dart:developer' as developer;

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/auth/auth_notifier.dart';
import 'core/database/database_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/supported_locales.dart';
import 'core/observability/app_logger.dart';
import 'core/observability/error_reporter.dart';
import 'core/platform/file_ops.dart' as platform;
import 'core/router/app_router.dart';
import 'core/startup/app_startup.dart';
import 'core/theme/app_theme.dart';
import 'features/recording/data/providers.dart';
import 'features/recording/data/services/recording_live_activity.dart';
import 'features/recording/data/services/recording_notification.dart';
import 'features/recording/data/services/recording_trash.dart';
import 'features/recording/data/services/recovery_coordinator.dart';
import 'features/sync/data/providers.dart';
import 'features/sync/data/services/background_upload_coordinator.dart';
import 'features/sync/data/services/upload_progress_visualizer.dart';
import 'features/sync/presentation/notifiers/sync_notifier.dart';
import 'l10n/app_localizations.dart';
import 'shared/preview_helpers.dart';

@Preview(name: 'Oral Collector App', wrapper: previewWrapper)
Widget oralCollectorPreview() => const OralCollectorApp();

void main() {
  // The container is created outside the guarded zone (it does not touch the
  // binding) and handed to the tree via UncontrolledProviderScope so the global
  // handlers and the widget tree share one reporter.
  final container = ProviderContainer();
  final reporter = container.read(errorReporterProvider);

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      usePathUrlStrategy();

      installGlobalErrorHandlers(reporter);
      installLogging(reporter: reporter);

      if (!kIsWeb && platform.isAndroidPlatform) {
        try {
          FlutterForegroundTask.initCommunicationPort();
        } on Exception {
          // noop
        }
      }

      if (!kIsWeb) {
        try {
          await RecordingNotification.instance.init();
        } on Exception {
          // noop
        }
      }

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const OralCollectorApp(),
        ),
      );
    },
    (error, stack) {
      developer.log(
        'Zone error',
        name: 'main',
        error: error,
        stackTrace: stack,
      );
      reporter.reportError(error, stack, level: ErrorLevel.fatal);
    },
  );
}

class OralCollectorApp extends ConsumerStatefulWidget {
  const OralCollectorApp({super.key});

  @override
  ConsumerState<OralCollectorApp> createState() => _OralCollectorAppState();
}

class _OralCollectorAppState extends ConsumerState<OralCollectorApp> {
  @override
  void initState() {
    super.initState();

    ref.read(appDatabaseProvider);

    Future.microtask(() async {
      // Local session restore is gated by appStartupProvider (the splash waits
      // on it). Once it settles, kick the online refresh and the rest of the
      // post-boot work. Token availability is storage-based, so this ordering
      // only removes the login flash — it does not gate uploads on auth.
      await ref.read(appStartupProvider.future);
      unawaited(
        ref.read(authNotifierProvider.notifier).refreshSessionIfOnline(),
      );

      // Reclaim recordings orphaned in `uploading` by a mid-upload crash so the
      // queue drains them again; must run before sync/listeners go live.
      await ref.read(localRecordingRepositoryProvider).resetStuckUploading();

      // Retire rows that spent their retry budget under the old generic
      // `failed` status (ENG-377). Fixing the writers only helps recordings
      // made after this build; devices are carrying these rows today, and each
      // one keeps the pending count high over a queue that refuses it.
      await ref
          .read(localRecordingRepositoryProvider)
          .normalizeExhaustedUploads();

      // Crash-recovery must clear any stale RecordingActiveFlag from a
      // previous run BEFORE the upload listeners go live. Otherwise the very
      // first processQueue() trigger reads a stuck-true flag and short-circuits
      // every chunk with pausedByRecording until the next state change.
      if (!kIsWeb) {
        unawaited(RecordingTrash.pruneOldTrash(maxAgeHours: 24));
        await ref.read(recoveryCoordinatorProvider).scanOnStartup();
        await RecordingLiveActivity.instance.endAll();
      }

      await _initBackgroundSync();

      if (!kIsWeb && platform.isIOSPlatform) {
        // iOS uploads run via background_downloader (URLSession background).
        // start() activates task tracking and reschedules tasks the OS dropped
        // while the app was suspended/killed, so uploads resume on next launch.
        try {
          await FileDownloader().start();
        } on Exception catch (e) {
          developer.log('FileDownloader.start failed', name: 'main', error: e);
        }
      }

      ref.read(recordingUploadListenerProvider);
      ref.read(uploadProgressVisualizerListenerProvider);
    });
  }

  Future<void> _initBackgroundSync() async {
    final bgSync = ref.read(backgroundSyncServiceProvider);
    await bgSync.initialize();

    if (kIsWeb || platform.isIOSPlatform) {
      bgSync.onWebSyncRequested = () {
        ref.read(syncNotifierProvider.notifier).processQueue();
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gate the router on the startup restore so its first redirect sees settled
    // auth state (no logged-out flash). A restore failure falls through to the
    // app logged-out — the router then sends the user to login.
    return ref
        .watch(appStartupProvider)
        .when(
          loading: () => const StartupSplash(),
          error: (_, _) => _buildApp(),
          data: (_) => _buildApp(),
        );
  }

  Widget _buildApp() {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Oral Collector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      themeAnimationDuration: Duration.zero,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // High ceiling only: never lowers the floor, so low-vision users keep
      // full up-scaling; bounds pathological OS settings (>2x) app-wide.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 2.0, child: child!),
    );
  }
}
