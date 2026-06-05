import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/auth/auth_notifier.dart';
import 'core/database/database_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/supported_locales.dart';
import 'core/observability/error_reporter.dart';
import 'core/platform/file_ops.dart' as platform;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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

      try {
        await dotenv.load(fileName: '.env');
      } on Exception {
        // noop
      }

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
      debugPrint('Zone error: $error\n$stack');
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
      ref.read(authNotifierProvider.notifier).tryAutoLogin();

      // Crash-recovery must clear any stale RecordingActiveFlag from a
      // previous run BEFORE the upload listeners go live. Otherwise the very
      // first processQueue() trigger reads a stuck-true flag and short-circuits
      // every chunk with pausedByRecording until the next state change.
      if (!kIsWeb) {
        RecordingTrash.pruneOldTrash(maxAgeHours: 24);
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
          debugPrint('FileDownloader.start failed: $e');
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
    );
  }
}
