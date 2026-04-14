import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/storyteller.dart';

class LocalStorytellerRepository {
  final AppDatabase _db;

  LocalStorytellerRepository(this._db);

  Future<void> upsertAll(List<Storyteller> items, String projectId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.localStorytellers,
      )..where((tbl) => tbl.projectId.equals(projectId))).go();
      for (final s in items) {
        await _db
            .into(_db.localStorytellers)
            .insert(_toCompanion(s), mode: InsertMode.insertOrReplace);
      }
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

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.localStorytellers,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  LocalStorytellersCompanion _toCompanion(Storyteller s) {
    return LocalStorytellersCompanion(
      id: Value(s.id),
      projectId: Value(s.projectId),
      name: Value(s.name),
      sex: Value(s.sex.toJson()),
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
      sex: StorytellerSex.fromJson(row.sex),
      age: row.age,
      location: row.location,
      dialect: row.dialect,
      externalAcceptanceConfirmed: row.externalAcceptanceConfirmed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
