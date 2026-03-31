import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'core/database/database_provider.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/supported_locales.dart';
import 'core/platform/file_ops.dart' as platform;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_notifier.dart';
import 'features/sync/data/providers.dart';
import 'features/sync/data/services/background_sync_service.dart';
import 'features/sync/presentation/notifiers/sync_notifier.dart';
import 'shared/preview_helpers.dart';

import 'l10n/app_localizations.dart';

@Preview(name: 'Oral Collector App', wrapper: previewWrapper)
Widget oralCollectorPreview() => const OralCollectorApp();

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
      };

      try {
        await dotenv.load(fileName: '.env');
      } on Exception {
        // noop
      }

      if (!kIsWeb && platform.isAndroidPlatform) {
        try {
          await Workmanager().initialize(callbackDispatcher);
        } on Exception {
          // noop
        }
      }

      runApp(const ProviderScope(child: OralCollectorApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
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

    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).tryAutoLogin();

      _initBackgroundSync();
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
