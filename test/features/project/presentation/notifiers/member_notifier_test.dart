import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/member_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

class _MockProjectRepo extends Mock implements ProjectRepository {}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);
}

void main() {
  late _MockProjectRepo repo;

  ProviderContainer makeContainer({required bool online}) => ProviderContainer(
    overrides: [
      projectRepositoryProvider.overrideWithValue(repo),
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(initialOnline: online),
      ),
    ],
  );

  setUp(() {
    repo = _MockProjectRepo();
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
}
