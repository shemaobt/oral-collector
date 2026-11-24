import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/router/app_router.dart';
import 'package:oral_collector/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/genre/domain/entities/genre.dart';
import 'package:oral_collector/features/genre/presentation/genre_detail_screen.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_notifier.dart';
import 'package:oral_collector/features/genre/presentation/notifiers/genre_state.dart';
import 'package:oral_collector/features/home/presentation/widgets/hero_genre_card.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';

import '../../support/router_app.dart';

class _WebLocal extends FakeLocal {
  @override
  Future<List<LocalRecording>> getPendingWebUploads() async => const [];

  @override
  Future<List<LocalRecording>> getAllLocalRecordings() async => const [];

  @override
  Future<({int count, double durationSeconds})> getLocalOnlyStats(
    String _,
  ) async => (count: 0, durationSeconds: 0.0);

  @override
  Future<({int count, double durationSeconds})> getLocalUnclassifiedStats(
    String _,
  ) async => (count: 0, durationSeconds: 0.0);
}

class _NoProject extends FakeProjectNotifier {
  @override
  ProjectState build() => const ProjectState(projects: <Project>[]);
}

class _Api extends FakeApi {
  bool deleted = false;

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
    String? reviewFlag,
  }) async => deleted ? [] : [serverRecording];
}

String addressOf(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

Future<ProviderContainer> _pumpWeb(
  WidgetTester tester, {
  required String at,
  List<Override> overrides = const [],
  bool settled = true,
}) => pumpApp(
  tester,
  at: at,
  settled: settled,
  overrides: [
    isWebPlatformProvider.overrideWithValue(true),
    localRecordingRepositoryProvider.overrideWithValue(_WebLocal()),
    ...overrides,
  ],
);

class _Admin extends FakeAuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u1', email: 'a@b.c', isPlatformAdmin: true),
  );
}

class _OneGenre extends FakeGenreNotifier {
  @override
  GenreState build() => const GenreState(
    genres: [
      Genre(id: 'g1', name: 'Folk Tale', sortOrder: 1, subcategories: []),
    ],
  );
}

final _asAdmin = authNotifierProvider.overrideWith(_Admin.new);

void main() {
  testWidgets('opening a recording from the list sets its address', (
    tester,
  ) async {
    final app = await _pumpWeb(tester, at: '/recordings');

    await tester.tap(find.byType(RecordingCard));
    await settle(tester);

    expect(addressOf(app), '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('the app built at a recording shows it, without the list', (
    tester,
  ) async {
    await _pumpWeb(tester, at: '/recording/r1');

    expect(find.byType(RecordingDetailScreen), findsOneWidget);
    expect(find.byType(RecordingsListScreen), findsNothing);
  });

  testWidgets('back from a recording shows the list without what was deleted', (
    tester,
  ) async {
    final api = _Api();
    final app = await _pumpWeb(
      tester,
      at: '/recordings',
      overrides: [recordingApiRepositoryProvider.overrideWithValue(api)],
    );
    await tester.tap(find.byType(RecordingCard));
    await settle(tester);

    api.deleted = true;
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(addressOf(app), '/recordings');
    expect(find.byType(RecordingCard), findsNothing);
  });

  testWidgets('back from the editor returns to its recording', (tester) async {
    final app = await _pumpWeb(tester, at: '/recording/r1/trim');
    expect(find.byType(TrimEditorScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(addressOf(app), '/recording/r1');
    expect(find.byType(RecordingDetailScreen), findsOneWidget);
  });

  testWidgets('import without an active project goes home', (tester) async {
    final app = await _pumpWeb(
      tester,
      at: '/import-file',
      settled: false,
      overrides: [projectNotifierProvider.overrideWith(_NoProject.new)],
    );

    expect(addressOf(app), '/home');
  });

  testWidgets('a genre opens from Home at its own address, back returns', (
    tester,
  ) async {
    final app = await _pumpWeb(
      tester,
      at: '/home',
      settled: false,
      overrides: [genreNotifierProvider.overrideWith(_OneGenre.new)],
    );
    await tester.pump();

    await tester.tap(find.byType(HeroGenreCard));
    await tester.pump();
    await tester.pump();
    expect(addressOf(app), '/genre/g1');
    expect(find.byType(GenreDetailScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(addressOf(app), '/home');
  });

  testWidgets('the admin opens from Profile at its own address, back returns', (
    tester,
  ) async {
    final app = await _pumpWeb(
      tester,
      at: '/profile',
      settled: false,
      overrides: [_asAdmin],
    );
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pump();

    await tester.tap(find.text('Admin Dashboard'));
    await tester.pump();
    await tester.pump();
    expect(addressOf(app), '/admin');
    expect(find.byType(AdminDashboardScreen), findsOneWidget);

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pump();
    expect(addressOf(app), '/profile');
  });
}
