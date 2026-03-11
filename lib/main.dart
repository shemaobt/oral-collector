import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'core/database/database_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_notifier.dart';
import 'features/sync/data/providers.dart';
import 'features/sync/data/services/background_sync_service.dart';
import 'features/sync/presentation/notifiers/sync_notifier.dart';
import 'shared/preview_helpers.dart';

@Preview(name: 'Oral Collector App', wrapper: previewWrapper)
Widget oralCollectorPreview() => const OralCollectorApp();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (!kIsWeb && Platform.isAndroid) {
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

    ref.read(appDatabaseProvider);

    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).tryAutoLogin();

      _initBackgroundSync();
    });
  }

  Future<void> _initBackgroundSync() async {
    final bgSync = ref.read(backgroundSyncServiceProvider);
    await bgSync.initialize();

    if (kIsWeb || Platform.isIOS) {
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
