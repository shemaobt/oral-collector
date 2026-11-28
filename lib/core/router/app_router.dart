import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/genre/presentation/genre_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/project/presentation/notifiers/project_notifier.dart';
import '../../features/project/presentation/project_settings_screen.dart';
import '../../features/project/presentation/projects_screen.dart';
import '../../features/recording/domain/entities/review_pendency.dart';
import '../../features/recording/presentation/file_import_screen.dart';
import '../../features/recording/presentation/notifiers/recording_session_notifier.dart';
import '../../features/recording/presentation/quick_recording_screen.dart';
import '../../features/recording/presentation/recording_detail_screen.dart';
import '../../features/recording/presentation/recording_flow_screen.dart';
import '../../features/recording/presentation/recordings_list_screen.dart';
import '../../features/recording/presentation/recovery_confirm_screen.dart';
import '../../features/recording/presentation/trim_editor_screen.dart';
import '../../features/storyteller/presentation/storyteller_form_screen.dart';
import '../../features/storyteller/presentation/storytellers_list_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../config/recording_config.dart';
import 'tab_in_use.dart';

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
  late final GoRouter router;

  router = GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      if (state.uri.scheme == RecordingConfig.liveActivityUrlScheme) {
        final currentPath = router.routerDelegate.currentConfiguration.uri.path;
        return currentPath.isEmpty ? '/home' : currentPath;
      }

      final isLoggedIn = notifier.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: _routesFor(ref, isWeb: ref.read(isWebPlatformProvider)),
  );

  return router;
});

GoRouterRedirect _requireActiveProject(Ref ref) =>
    (context, state) => ref.read(projectNotifierProvider).activeProject != null
    ? null
    : '/home';

List<RouteBase> _routesFor(Ref ref, {required bool isWeb}) => [
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/reset-password',
    builder: (context, state) =>
        ResetPasswordScreen(token: state.uri.queryParameters['token']),
  ),

  if (!isWeb) ...[
    GoRoute(
      path: '/genre/:id',
      builder: (context, state) =>
          GenreDetailScreen(genreId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/record-flow',
      redirect: _requireActiveProject(ref),
      builder: (context, state) => RecordingFlowScreen(
        genreId: state.uri.queryParameters['genreId'],
        subcategoryId: state.uri.queryParameters['subcategoryId'],
      ),
    ),
    GoRoute(
      path: '/recording/:id',
      builder: (context, state) =>
          RecordingDetailScreen(recordingId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/recording/:id/trim',
      builder: (context, state) =>
          TrimEditorScreen(recordingId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/import-file',
      redirect: _requireActiveProject(ref),
      builder: (context, state) {
        final extra = state.extra;
        return FileImportScreen(
          initialFiles: extra is List<XFile> ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/project/:id/settings',
      builder: (context, state) =>
          ProjectSettingsScreen(projectId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers',
      builder: (context, state) => StorytellersListScreen(
        projectId: state.pathParameters['projectId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers/new',
      builder: (context, state) => StorytellerFormScreen(
        projectId: state.pathParameters['projectId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers/:storytellerId/edit',
      builder: (context, state) => StorytellerFormScreen(
        projectId: state.pathParameters['projectId'] ?? '',
        storytellerId: state.pathParameters['storytellerId'],
      ),
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) => '/profile',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],

  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      for (final routes in [
        _homeRoutes(isWeb: isWeb),
        _recordRoutes(ref),
        _recordingsRoutes(ref, isWeb: isWeb),
        _projectsRoutes(isWeb: isWeb),
        _profileRoutes(),
        if (isWeb) _adminRoutes(),
      ])
        StatefulShellBranch(routes: routes),
    ],
  ),
];

class _FreshOnEveryEntry extends ConsumerStatefulWidget {
  const _FreshOnEveryEntry({required this.address, required this.child});

  final Uri address;
  final Widget child;

  @override
  ConsumerState<_FreshOnEveryEntry> createState() => _FreshOnEveryEntryState();
}

class _FreshOnEveryEntryState extends ConsumerState<_FreshOnEveryEntry> {
  int _departures = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(tabInUseProvider, (was, now) {
      if (was == ShellTab.record) setState(() => _departures++);
    });
    return KeyedSubtree(
      key: ValueKey((_departures, widget.address)),
      child: widget.child,
    );
  }
}

List<RouteBase> _homeRoutes({required bool isWeb}) => [
  GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  if (isWeb) ...[
    GoRoute(
      path: '/genre/:id',
      builder: (context, state) =>
          GenreDetailScreen(genreId: state.pathParameters['id'] ?? ''),
    ),
  ],
];

List<RouteBase> _recordRoutes(Ref ref) => [
  GoRoute(
    path: '/record',
    redirect: _requireActiveProject(ref),
    builder: (context, state) => _FreshOnEveryEntry(
      address: state.uri,
      child: RecordingFlowScreen(
        genreId: state.uri.queryParameters['genreId'],
        subcategoryId: state.uri.queryParameters['subcategoryId'],
      ),
    ),
  ),
  GoRoute(
    path: '/quick-record',
    redirect: _requireActiveProject(ref),
    builder: (context, state) => _FreshOnEveryEntry(
      address: state.uri,
      child: const QuickRecordingScreen(),
    ),
  ),
  GoRoute(
    path: '/recovery-confirm',
    redirect: _requireActiveProject(ref),
    builder: (context, state) => _FreshOnEveryEntry(
      address: state.uri,
      child: const RecoveryConfirmScreen(),
    ),
  ),
];

List<RouteBase> _recordingsRoutes(Ref ref, {required bool isWeb}) => [
  GoRoute(
    path: '/recordings',
    builder: (context, state) => RecordingsListScreen(
      initialGenreId: state.uri.queryParameters['genreId'],
      initialSubcategoryId: state.uri.queryParameters['subcategoryId'],
      // Resolved here, not passed on as a raw string: an unknown code
      // answers null and the list simply opens unfiltered, rather than
      // sending the server something it would refuse with a 422.
      initialReviewFlag: pendencyKindForCode(
        state.uri.queryParameters['reviewFlag'] ?? '',
      ),
    ),
  ),
  if (isWeb) ...[
    GoRoute(
      path: '/import-file',
      redirect: _requireActiveProject(ref),
      builder: (context, state) {
        final extra = state.extra;
        return FileImportScreen(
          initialFiles: extra is List<XFile> ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/recording/:id',
      builder: (context, state) =>
          RecordingDetailScreen(recordingId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/recording/:id/trim',
      builder: (context, state) =>
          TrimEditorScreen(recordingId: state.pathParameters['id'] ?? ''),
    ),
  ],
];

List<RouteBase> _projectsRoutes({required bool isWeb}) => [
  GoRoute(
    path: '/projects',
    builder: (context, state) => const ProjectsScreen(),
  ),
  if (isWeb) ...[
    GoRoute(
      path: '/project/:id/settings',
      builder: (context, state) =>
          ProjectSettingsScreen(projectId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers',
      builder: (context, state) => StorytellersListScreen(
        projectId: state.pathParameters['projectId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers/new',
      builder: (context, state) => StorytellerFormScreen(
        projectId: state.pathParameters['projectId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/project/:projectId/storytellers/:storytellerId/edit',
      builder: (context, state) => StorytellerFormScreen(
        projectId: state.pathParameters['projectId'] ?? '',
        storytellerId: state.pathParameters['storytellerId'],
      ),
    ),
  ],
];

List<RouteBase> _profileRoutes() => [
  GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
];

List<RouteBase> _adminRoutes() => [
  GoRoute(
    path: '/admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
];
