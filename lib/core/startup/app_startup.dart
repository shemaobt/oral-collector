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

/// Minimal themed splash shown while [appStartupProvider] resolves. It brings
/// its own Directionality/theme because the router's app does not exist yet.
///
/// It must not be a [MaterialApp]: that app's root Navigator reports its `/`
/// route to the engine, which on web rewrites the address bar before the router
/// reads it, so every opened link (the password-reset link first) became `/`.
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (context) {
          final dark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: theme,
              child: Material(
                color: theme.scaffoldBackgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        },
      ),
    );
  }
}
