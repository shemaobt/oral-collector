import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
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

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, _) {
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      if (!kIsWeb) ...[
        GoRoute(
          path: '/genre/:id',
          builder: (context, state) =>
              GenreDetailScreen(genreId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/recording/:id',
          builder: (context, state) => RecordingDetailScreen(
            recordingId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/recording/:id/trim',
          builder: (context, state) =>
              TrimEditorScreen(recordingId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/import-file',
          builder: (context, state) => const FileImportScreen(),
        ),
        GoRoute(
          path: '/project/:id/settings',
          builder: (context, state) => ProjectSettingsScreen(
            projectId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/admin',
          redirect: (context, state) => '/profile',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/record',
            redirect: (context, state) => kIsWeb ? '/recordings' : null,
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

          if (kIsWeb) ...[
            GoRoute(
              path: '/genre/:id',
              builder: (context, state) =>
                  GenreDetailScreen(genreId: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: '/recording/:id',
              builder: (context, state) => RecordingDetailScreen(
                recordingId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/recording/:id/trim',
              builder: (context, state) => TrimEditorScreen(
                recordingId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/project/:id/settings',
              builder: (context, state) => ProjectSettingsScreen(
                projectId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ],
      ),
    ],
  );
});
