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
import 'package:oral_collector/features/project/presentation/project_settings_screen.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/recording/presentation/recording_flow_screen.dart';
import 'package:oral_collector/features/recording/presentation/recordings_list_screen.dart';
import 'package:oral_collector/features/recording/presentation/trim_editor_screen.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/recording/presentation/widgets/register_selection_step.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_notifier.dart';
import 'package:oral_collector/features/storyteller/presentation/notifiers/project_storytellers_state.dart';
import 'package:oral_collector/features/storyteller/presentation/storyteller_form_screen.dart';
import 'package:oral_collector/shared/widgets/app_shell/floating_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Storyteller _storyteller(String id, String name) => Storyteller(
  id: id,
  projectId: 'p1',
  name: name,
  sex: StorytellerSex.female,
  externalAcceptanceConfirmed: true,
  createdByUserId: 'u1',
  createdAt: DateTime(2026, 1, 1),
);

class _Server extends ProjectStorytellersNotifier {
  final _stored = [_storyteller('s1', 'Ana Mbala')];

  @override
  Future<void> fetch(String projectId) async =>
      state = ProjectStorytellersState(
        projectId: projectId,
        storytellers: [..._stored],
      );

  @override
  Future<Storyteller?> create({
    required String projectId,
    required String name,
    required StorytellerSex sex,
    int? age,
    String? location,
    String? dialect,
    required bool externalAcceptanceConfirmed,
  }) async {
    _stored.add(_storyteller('new', name));
    return null;
  }
}

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

class _GenreWithSubcategory extends FakeGenreNotifier {
  @override
  GenreState build() => const GenreState(
    genres: [
      Genre(
        id: 'g1',
        name: 'Folk Tale',
        sortOrder: 1,
        subcategories: [Subcategory(id: 's1', genreId: 'g1', name: 'Fable')],
      ),
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

  testWidgets('Recordings returns to the open recording after a visit to Home, '
      'and its own tab goes back to the list', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final app = await _pumpWeb(tester, at: '/recording/r1');
    Future<void> tapTab(IconData icon) async {
      await tester.tap(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.byIcon(icon),
        ),
      );
      await settle(tester);
    }

    await tapTab(LucideIcons.layoutGrid);
    await tapTab(LucideIcons.listMusic);
    expect(addressOf(app), '/recording/r1');

    await tapTab(LucideIcons.listMusic);
    expect(addressOf(app), '/recordings');
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

  testWidgets('the microphone on a subcategory opens the flow at its address', (
    tester,
  ) async {
    final app = await _pumpWeb(
      tester,
      at: '/record',
      settled: false,
      overrides: [
        genreNotifierProvider.overrideWith(_GenreWithSubcategory.new),
      ],
    );
    await tester.pump();
    app.read(routerProvider).go('/genre/g1');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(LucideIcons.mic),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(addressOf(app), '/record?genreId=g1&subcategoryId=s1');
    final flow = tester.widget<RecordingFlowScreen>(
      find.byType(RecordingFlowScreen),
    );
    expect((flow.genreId, flow.subcategoryId), ('g1', 's1'));
    expect(find.byType(RegisterSelectionStep), findsOneWidget);
  });

  testWidgets(
    'a project opens from Projects at its own address, back returns',
    (tester) async {
      final app = await _pumpWeb(tester, at: '/projects');

      await tester.tap(find.text(project.name));
      await tester.pump();
      await tester.pump();
      expect(addressOf(app), '/project/p1/settings');
      expect(find.byType(ProjectSettingsScreen), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pump();
      expect(addressOf(app), '/projects');
    },
  );

  testWidgets('the storytellers and their form each keep an address', (
    tester,
  ) async {
    final app = await _pumpWeb(
      tester,
      at: '/project/p1/storytellers',
      overrides: [
        projectStorytellersNotifierProvider.overrideWith(_Server.new),
      ],
    );

    await tester.tap(find.byIcon(LucideIcons.plus));
    await settle(tester);
    expect(addressOf(app), '/project/p1/storytellers/new');
    expect(find.byType(StorytellerFormScreen), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await settle(tester);
    expect(addressOf(app), '/project/p1/storytellers');

    await tester.tap(find.text('Ana Mbala'));
    await settle(tester);
    expect(addressOf(app), '/project/p1/storytellers/s1/edit');

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await settle(tester);
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await settle(tester);
    expect(addressOf(app), '/projects');
  });

  testWidgets('a saved storyteller is in the list, with no refresh', (
    tester,
  ) async {
    final app = await _pumpWeb(
      tester,
      at: '/project/p1/storytellers/new',
      overrides: [
        projectStorytellersNotifierProvider.overrideWith(_Server.new),
      ],
    );
    await tester.enterText(find.byType(TextFormField).first, 'Beto Nzinga');
    await tester.tap(find.text('Male'));
    await tester.tap(find.byType(CheckboxListTile));
    tester.view.physicalSize = const Size(1170, 4500);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await settle(tester);

    expect(addressOf(app), '/project/p1/storytellers');
    expect(find.text('Beto Nzinga'), findsOneWidget);
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
