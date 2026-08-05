import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_notifier.dart';
import '../theme/app_theme.dart';

/// Awaits the must-finish-before-first-frame work — currently the local session
/// restore — so the router redirects on settled auth state instead of flashing
/// the login screen on cold start. The network refresh is intentionally NOT
/// awaited here; it runs after the gate resolves.
final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(authNotifierProvider.notifier).restoreSession();
});

/// Minimal themed splash shown while [appStartupProvider] resolves. It is its
/// own [MaterialApp] so it has Directionality/theme before the router exists.
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
