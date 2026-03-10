import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'core/database/database_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/providers/auth_provider.dart';
import 'features/sync/data/providers/sync_provider.dart';
import 'features/sync/data/services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize workmanager for background sync on mobile platforms.
  if (!kIsWeb) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
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
    // Initialize local database
    ref.read(appDatabaseProvider);
    // Check auth state on startup
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).tryAutoLogin();
      // Initialize background sync scheduling
      _initBackgroundSync();
    });
  }

  Future<void> _initBackgroundSync() async {
    final bgSync = ref.read(backgroundSyncServiceProvider);
    await bgSync.initialize();

    // On web, wire the timer callback to trigger sync via SyncNotifier.
    if (kIsWeb) {
      bgSync.onWebSyncRequested = () {
        ref.read(syncNotifierProvider.notifier).processQueue();
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Oral Collector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
