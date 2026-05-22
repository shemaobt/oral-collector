import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';

void main() {
  late AppDatabase db;
  late LocalStorytellerRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalStorytellerRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Storyteller makeStoryteller({
    required String id,
    String projectId = 'proj-1',
    String name = 'João Silva',
  }) {
    return Storyteller(
      id: id,
      projectId: projectId,
      name: name,
      sex: StorytellerSex.male,
      externalAcceptanceConfirmed: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('insertLocal + getPendingSyncs', () {
    test(
      'storyteller inserted with syncStatus=local appears in getPendingSyncs',
      () async {
        final s = makeStoryteller(id: 'stl_local_1');

        await repo.insertLocal(s, syncStatus: 'local');

        final pending = await repo.getPendingSyncs();
        expect(pending.length, 1);
        expect(pending.single.id, 'stl_local_1');
        expect(pending.single.syncStatus, 'local');
        expect(pending.single.serverId, isNull);
      },
    );
  });

  group('markUploaded', () {
    test(
      'after markUploaded the storyteller no longer appears in getPendingSyncs',
      () async {
        final s = makeStoryteller(id: 'stl_a');
        await repo.insertLocal(s, syncStatus: 'local');

        await repo.markUploaded('stl_a', 'srv-1');

        final pending = await repo.getPendingSyncs();
        expect(pending, isEmpty);
      },
    );

    test(
      'after markUploaded the row has serverId set and syncStatus=synced',
      () async {
        final s = makeStoryteller(id: 'stl_b', projectId: 'proj-1');
        await repo.insertLocal(s, syncStatus: 'local');

        await repo.markUploaded('stl_b', 'srv-2');

        final row = await repo.getRowById('stl_b');
        expect(row, isNotNull);
        expect(row!.serverId, 'srv-2');
        expect(row.syncStatus, 'synced');
      },
    );
  });

  group('markFailed', () {
    test('markFailed increments retryCount and keeps row in pending', () async {
      final s = makeStoryteller(id: 'stl_fail_1');
      await repo.insertLocal(s, syncStatus: 'local');

      await repo.markFailed('stl_fail_1');

      final pending = await repo.getPendingSyncs();
      expect(pending.length, 1);
      expect(pending.single.retryCount, 1);
      expect(pending.single.lastRetryAt, isNotNull);
      expect(pending.single.syncStatus, 'failed');
    });

    test('markFailed multiple times accumulates retryCount', () async {
      final s = makeStoryteller(id: 'stl_fail_2');
      await repo.insertLocal(s, syncStatus: 'local');

      await repo.markFailed('stl_fail_2');
      await repo.markFailed('stl_fail_2');
      await repo.markFailed('stl_fail_2');

      final pending = await repo.getPendingSyncs();
      expect(pending.single.retryCount, 3);
    });

    test(
      'storyteller with retryCount>=5 does NOT appear in getPendingSyncs',
      () async {
        final s = makeStoryteller(id: 'stl_max');
        await repo.insertLocal(s, syncStatus: 'local');

        for (var i = 0; i < 5; i++) {
          await repo.markFailed('stl_max');
        }

        final pending = await repo.getPendingSyncs();
        expect(pending, isEmpty);
      },
    );
  });

  group('markUploading', () {
    test('markUploading is a no-op for pending visibility', () async {
      final s = makeStoryteller(id: 'stl_upl');
      await repo.insertLocal(s, syncStatus: 'local');

      await repo.markUploading('stl_upl');

      final pending = await repo.getPendingSyncs();
      expect(
        pending.where((p) => p.id == 'stl_upl').length,
        1,
        reason:
            'uploading row should still be returned so a retry can resume it',
      );
    });
  });

  group('upsertAll preserves pending rows', () {
    test(
      'server snapshot via upsertAll does NOT delete locally pending rows',
      () async {
        final pendingLocal = makeStoryteller(
          id: 'stl_pending',
          projectId: 'proj-1',
          name: 'Pending One',
        );
        await repo.insertLocal(pendingLocal, syncStatus: 'local');

        final serverItem = makeStoryteller(
          id: 'srv-100',
          projectId: 'proj-1',
          name: 'From Server',
        );
        await repo.upsertAll([serverItem], 'proj-1');

        final list = await repo.getByProject('proj-1');
        final ids = list.map((s) => s.id).toSet();
        expect(ids, containsAll(['stl_pending', 'srv-100']));
      },
    );

    test(
      'upsertAll updates existing synced rows but leaves pending intact',
      () async {
        final serverItem = makeStoryteller(
          id: 'srv-existing',
          projectId: 'proj-1',
          name: 'Old Name',
        );
        await repo.upsertAll([serverItem], 'proj-1');

        final pendingLocal = makeStoryteller(
          id: 'stl_keep',
          projectId: 'proj-1',
        );
        await repo.insertLocal(pendingLocal, syncStatus: 'local');

        final updated = makeStoryteller(
          id: 'srv-existing',
          projectId: 'proj-1',
          name: 'New Name',
        );
        await repo.upsertAll([updated], 'proj-1');

        final list = await repo.getByProject('proj-1');
        final names = {for (final s in list) s.id: s.name};
        expect(names['srv-existing'], 'New Name');
        expect(names['stl_keep'], 'João Silva');

        final pending = await repo.getPendingSyncs();
        expect(pending.any((p) => p.id == 'stl_keep'), isTrue);
      },
    );
  });
}
