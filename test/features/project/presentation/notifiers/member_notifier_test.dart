import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/errors/app_exception.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project_member.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockProjectRepo extends Mock implements ProjectRepository {}

class _RecordingReporter implements ErrorReporter {
  final List<Object> reported = [];

  @override
  void reportError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, String>? tags,
    Map<String, Object?>? context,
    ErrorLevel level = ErrorLevel.error,
  }) {
    reported.add(error);
  }

  @override
  void addBreadcrumb(
    String message, {
    String? category,
    ErrorLevel level = ErrorLevel.info,
    Map<String, Object?>? data,
  }) {}

  @override
  void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, Object?>? data,
  }) {}

  @override
  void clearUser() {}

  @override
  void setTag(String key, String value) {}
}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}

ProjectMember _makeMember(String userId, String email) => ProjectMember(
  id: 'mem-$userId',
  projectId: 'proj-1',
  userId: userId,
  email: email,
);

void main() {
  late _MockProjectRepo repo;
  late _RecordingReporter reporter;

  ProviderContainer makeContainer({required bool online}) => ProviderContainer(
    overrides: [
      projectRepositoryProvider.overrideWithValue(repo),
      errorReporterProvider.overrideWithValue(reporter),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(initialOnline: online),
      ),
    ],
  );

  setUp(() {
    repo = _MockProjectRepo();
    reporter = _RecordingReporter();
  });

  group('MemberNotifier.fetchMembers — offline', () {
    test('offline does not call API, ends not loading', () async {
      final container = makeContainer(online: false);
      addTearDown(container.dispose);

      await container
          .read(memberNotifierProvider.notifier)
          .fetchMembers('proj-1');

      final state = container.read(memberNotifierProvider);
      expect(state.isLoading, isFalse);
      verifyNever(() => repo.listMembers(any()));
    });
  });

  group('MemberNotifier.fetchMembers — online', () {
    test('online fetches from API and populates members', () async {
      final fromApi = [
        _makeMember('u1', 'alice@example.com'),
        _makeMember('u2', 'bob@example.com'),
      ];
      when(() => repo.listMembers('proj-1')).thenAnswer((_) async => fromApi);

      final container = makeContainer(online: true);
      addTearDown(container.dispose);

      await container
          .read(memberNotifierProvider.notifier)
          .fetchMembers('proj-1');

      final state = container.read(memberNotifierProvider);
      expect(state.members.map((m) => m.userId), ['u1', 'u2']);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      verify(() => repo.listMembers('proj-1')).called(1);
    });
  });

  group('MemberNotifier.fetchMembers — offline → online transition', () {
    test(
      'first fetch offline short-circuits; second fetch (post-flip) hits the API',
      () async {
        when(
          () => repo.listMembers('proj-1'),
        ).thenAnswer((_) async => [_makeMember('u1', 'alice@example.com')]);

        final fakeSync = _FakeSyncNotifier(initialOnline: false);
        final container = ProviderContainer(
          overrides: [
            projectRepositoryProvider.overrideWithValue(repo),
            syncNotifierProvider.overrideWith(() => fakeSync),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(memberNotifierProvider.notifier);

        await notifier.fetchMembers('proj-1');
        verifyNever(() => repo.listMembers(any()));

        fakeSync.setOnline(true);
        await notifier.fetchMembers('proj-1');

        verify(() => repo.listMembers('proj-1')).called(1);
        final state = container.read(memberNotifierProvider);
        expect(state.members.map((m) => m.userId), ['u1']);
      },
    );
  });

  group('MemberNotifier — telemetria de erro', () {
    test('um 401 não é telemetrado, mas o erro é exposto à UI', () async {
      when(
        () => repo.listMembers('proj-1'),
      ).thenThrow(const UnauthorizedException());
      final container = makeContainer(online: true);
      addTearDown(container.dispose);

      await container
          .read(memberNotifierProvider.notifier)
          .fetchMembers('proj-1');

      expect(container.read(memberNotifierProvider).error, isNotNull);
      expect(reporter.reported, isEmpty);
    });

    test('um erro de servidor é telemetrado', () async {
      when(
        () => repo.listMembers('proj-1'),
      ).thenThrow(const ServerException(statusCode: 500));
      final container = makeContainer(online: true);
      addTearDown(container.dispose);

      await container
          .read(memberNotifierProvider.notifier)
          .fetchMembers('proj-1');

      expect(reporter.reported, hasLength(1));
    });
  });
}
