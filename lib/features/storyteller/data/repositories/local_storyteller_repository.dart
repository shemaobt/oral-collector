import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/storyteller.dart';

const _pendingStatuses = ['local', 'failed', 'uploading'];
const _maxRetries = 5;

class LocalStorytellerRepository {
  final AppDatabase _db;

  LocalStorytellerRepository(this._db);

  Future<void> upsertAll(List<Storyteller> items, String projectId) async {
    await _db.batch((batch) {
      batch.deleteWhere(
        _db.localStorytellers,
        (tbl) =>
            tbl.projectId.equals(projectId) &
            tbl.syncStatus.isNotIn(_pendingStatuses),
      );
      batch.insertAll(
        _db.localStorytellers,
        items.map(_toCompanion).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<Storyteller>> getByProject(String projectId) async {
    final rows =
        await (_db.select(_db.localStorytellers)
              ..where((tbl) => tbl.projectId.equals(projectId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<Storyteller?> getById(String id) async {
    final row = await (_db.select(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<LocalStoryteller?> getRowById(String id) async {
    return (_db.select(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> insertLocal(
    Storyteller storyteller, {
    String syncStatus = 'local',
  }) async {
    await _db
        .into(_db.localStorytellers)
        .insert(
          _toCompanion(storyteller).copyWith(syncStatus: Value(syncStatus)),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<LocalStoryteller>> getPendingSyncs() async {
    return (_db.select(_db.localStorytellers)..where(
          (tbl) =>
              tbl.syncStatus.isIn(_pendingStatuses) &
              tbl.retryCount.isSmallerThanValue(_maxRetries),
        ))
        .get();
  }

  Future<void> markUploading(String id) async {
    await (_db.update(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).write(
      const LocalStorytellersCompanion(syncStatus: Value('uploading')),
    );
  }

  Future<void> markUploaded(String localId, String serverId) async {
    await (_db.update(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(localId))).write(
      LocalStorytellersCompanion(
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
      ),
    );
  }

  Future<void> markFailed(String id) async {
    final row = await getRowById(id);
    if (row == null) return;
    await (_db.update(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).write(
      LocalStorytellersCompanion(
        syncStatus: const Value('failed'),
        retryCount: Value(row.retryCount + 1),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }

  LocalStorytellersCompanion _toCompanion(Storyteller s) {
    return LocalStorytellersCompanion(
      id: Value(s.id),
      projectId: Value(s.projectId),
      name: Value(s.name),
      sex: Value(s.sex.toWire()),
      age: Value(s.age),
      location: Value(s.location),
      dialect: Value(s.dialect),
      externalAcceptanceConfirmed: Value(s.externalAcceptanceConfirmed),
      createdAt: Value(s.createdAt),
      updatedAt: Value(s.updatedAt),
    );
  }

  Storyteller _fromRow(LocalStoryteller row) {
    return Storyteller(
      id: row.id,
      projectId: row.projectId,
      name: row.name,
      sex: StorytellerSex.fromWire(row.sex),
      age: row.age,
      location: row.location,
      dialect: row.dialect,
      externalAcceptanceConfirmed: row.externalAcceptanceConfirmed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
