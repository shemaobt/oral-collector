import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/admin/data/providers.dart';
import 'package:oral_collector/features/admin/domain/repositories/admin_repository.dart';
import 'package:oral_collector/features/admin/presentation/notifiers/admin_notifier.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late ProviderContainer container;
  late MockAdminRepository repo;

  setUp(() {
    repo = MockAdminRepository();
    when(() => repo.fetchCleaningQueue()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  group('triggerBatchClean', () {
    test('counts successes, skips failures, and refreshes once', () async {
      when(() => repo.triggerClean('ok-1')).thenAnswer((_) async {});
      when(() => repo.triggerClean('bad')).thenThrow(Exception('nope'));
      when(() => repo.triggerClean('ok-2')).thenAnswer((_) async {});

      final notifier = container.read(adminNotifierProvider.notifier);
      final count = await notifier.triggerBatchClean(['ok-1', 'bad', 'ok-2']);

      expect(count, 2);
      // a failure mid-batch must not abort the remaining items
      verify(() => repo.triggerClean('ok-2')).called(1);
      verify(() => repo.fetchCleaningQueue()).called(1);
    });

    test('fans out the triggers concurrently (not one-at-a-time)', () async {
      var active = 0;
      var maxActive = 0;
      final gate = Completer<void>();
      when(() => repo.triggerClean(any())).thenAnswer((_) async {
        active++;
        if (active > maxActive) maxActive = active;
        await gate.future;
        active--;
      });

      final notifier = container.read(adminNotifierProvider.notifier);
      final ids = List.generate(10, (i) => 'r$i');
      final future = notifier.triggerBatchClean(ids);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Bounded fan-out: runs concurrently but capped at the batch limit (6),
      // so an accidental unbounded Future.wait (10 in flight) is also caught.
      expect(maxActive, 6);

      gate.complete();
      await future;
    });
  });
}
