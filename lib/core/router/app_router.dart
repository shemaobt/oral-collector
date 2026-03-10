import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/genre/presentation/genre_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/project/presentation/project_settings_screen.dart';
import '../../features/project/presentation/projects_screen.dart';
import '../../features/recording/presentation/file_import_screen.dart';
import '../../features/recording/presentation/recording_detail_screen.dart';
import '../../features/recording/presentation/recording_flow_screen.dart';
import '../../features/recording/presentation/recordings_list_screen.dart';
import '../../features/recording/presentation/trim_editor_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';

// Bridge between Riverpod auth state and GoRouter's refreshListenable.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;

  bool get isAuthenticated => _ref.read(authNotifierProvider).isAuthenticated;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Auth routes (outside shell — no bottom nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Genre detail (outside shell — uses its own back navigation)
      GoRoute(
        path: '/genre/:id',
        builder: (context, state) => GenreDetailScreen(
          genreId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Recording detail (outside shell — uses its own back navigation)
      GoRoute(
        path: '/recording/:id',
        builder: (context, state) => RecordingDetailScreen(
          recordingId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Trim editor (outside shell — uses its own back navigation)
      GoRoute(
        path: '/recording/:id/trim',
        builder: (context, state) => TrimEditorScreen(
          recordingId: state.pathParameters['id'] ?? '',
        ),
      ),

      // File import (outside shell — uses its own back navigation)
      GoRoute(
        path: '/import-file',
        builder: (context, state) => const FileImportScreen(),
      ),

      // Project settings (outside shell — uses its own back navigation)
      GoRoute(
        path: '/project/:id/settings',
        builder: (context, state) => ProjectSettingsScreen(
          projectId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Main app routes wrapped in AppShell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/record',
            builder: (context, state) => RecordingFlowScreen(
              genreId: state.uri.queryParameters['genreId'],
              subcategoryId: state.uri.queryParameters['subcategoryId'],
            ),
          ),
          GoRoute(
            path: '/recordings',
            builder: (context, state) => const RecordingsListScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
