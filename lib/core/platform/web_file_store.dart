import 'dart:math' as math;
import 'dart:typed_data';

import 'package:idb_shim/idb.dart';

/// Durable byte storage for the web build, backed by IndexedDB.
///
/// The browser gives the app no filesystem, so `file_ops_web.dart` used to keep
/// recorded audio in a module-level map. That map died with the tab while the
/// Drift metadata row (also IndexedDB) survived, so a reload left a recording
/// whose audio no longer existed anywhere — the defect ENG-421 describes. The
/// bytes now live in their own IndexedDB database, which outlives the page.
///
/// The [IdbFactory] is injected so the storage engine is a seam: production
/// passes the browser's, tests pass `idb_shim`'s in-memory implementation,
/// which is a complete implementation of the same API and outlives any single
/// store instance the same way the browser's does.
///
/// A missing path reads as empty rather than throwing, which is the behaviour
/// the web callers already branch on (`bytes.isEmpty` in `confirmation_step`).
class WebFileStore {
  WebFileStore(this._factory);

  static const String _databaseName = 'oral_collector_files';
  static const String _storeName = 'files';
  static const int _schemaVersion = 1;

  final IdbFactory _factory;
  Future<Database>? _opening;

  Future<Database> _database() {
    final pending = _opening;
    if (pending != null) return pending;
    final opened = _factory.open(
      _databaseName,
      version: _schemaVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        event.database.createObjectStore(_storeName);
      },
    );
    // A refused open is not cached: a browser can block one call (another tab
    // holding a version change) and allow the next. Caching the future that
    // carries the reset, not the raw one, makes that true for every waiter.
    return _opening = opened.catchError((Object error, StackTrace stack) {
      _opening = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<T> _inTransaction<T>(
    String mode,
    Future<T> Function(ObjectStore store) action,
  ) async {
    final database = await _database();
    final transaction = database.transaction(_storeName, mode);
    final result = await action(transaction.objectStore(_storeName));
    await transaction.completed;
    return result;
  }

  Future<bool> exists(String path) async {
    final count = await _inTransaction(
      idbModeReadOnly,
      (store) => store.count(path),
    );
    return count > 0;
  }

  /// Reads the whole value: IndexedDB has no size-only lookup. Use [exists]
  /// for a cheap probe — that one does not materialize the bytes.
  Future<int> length(String path) async => (await read(path)).length;

  Future<Uint8List> read(String path) async {
    final value = await _inTransaction(
      idbModeReadOnly,
      (store) => store.getObject(path),
    );
    return value == null ? Uint8List(0) : value as Uint8List;
  }

  Future<void> write(String path, Uint8List bytes) =>
      _inTransaction(idbModeReadWrite, (store) => store.put(bytes, path));

  Future<void> delete(String path) =>
      _inTransaction(idbModeReadWrite, (store) => store.delete(path));

  Future<void> copy(String from, String to) async {
    final value = await _inTransaction(
      idbModeReadOnly,
      (store) => store.getObject(from),
    );
    if (value == null) return;
    await write(to, value as Uint8List);
  }

  Future<Uint8List> readChunk(String path, int offset, int length) async {
    final bytes = await read(path);
    final start = math.min(offset, bytes.length);
    final end = math.min(start + length, bytes.length);
    return end <= start ? Uint8List(0) : bytes.sublist(start, end);
  }
}
