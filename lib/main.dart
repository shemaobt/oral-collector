import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'core/database/database_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/supported_locales.dart';
import 'core/platform/file_ops.dart' as platform;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_notifier.dart';
import 'features/recording/data/services/recording_live_activity.dart';
import 'features/recording/data/services/recording_notification.dart';
import 'features/recording/data/services/recording_trash.dart';
import 'features/recording/data/services/recovery_coordinator.dart';
import 'features/sync/data/providers.dart';
import 'features/sync/data/services/background_upload_coordinator.dart';
import 'features/sync/data/services/upload_progress_visualizer.dart';
import 'features/sync/presentation/notifiers/sync_notifier.dart';
import 'shared/preview_helpers.dart';

import 'l10n/app_localizations.dart';

@Preview(name: 'Oral Collector App', wrapper: previewWrapper)
Widget oralCollectorPreview() => const OralCollectorApp();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

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

    try {
      // §5 progress UX (Android): determinate progress notification while a
      // chunk is in flight; dismissed automatically on complete/cancel.
      // iOS path uses the upload Live Activity instead (§5 iOS).
      FileDownloader().configureNotification(
        running: const TaskNotification(
          'Uploading recording',
          'Sending audio in the background',
        ),
        complete: const TaskNotification(
          'Upload complete',
          'Recording saved to the cloud',
        ),
        error: const TaskNotification(
          'Upload failed',
          'Will retry when the connection improves',
        ),
        progressBar: true,
      );
    } on Exception {
      // noop
    }
  }

  runApp(const ProviderScope(child: OralCollectorApp()));
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

      _initBackgroundSync();

      // Wire the recording-state -> upload coordinator listener.
      ref.read(recordingUploadListenerProvider);

      // Wire sync state -> Upload Live Activity (iOS).
      ref.read(uploadProgressVisualizerListenerProvider);

      if (!kIsWeb) {
        RecordingTrash.pruneOldTrash(maxAgeHours: 24);
        await ref.read(recoveryCoordinatorProvider).scanOnStartup();
        await RecordingLiveActivity.instance.endAll();
      }
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
