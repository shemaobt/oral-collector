import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../repositories/recording_session_repository.dart';
import 'segment_paths.dart';
import 'wav_header_repair.dart';

typedef DocumentsPathResolver = Future<String> Function();

/// A metade da recuperação que varre o diretório de documentos.
///
/// Tudo o que precisa de `dart:io` mora aqui, e é por isso que o coordenador
/// deixou de precisar dele (ENG-519, fatia 2). O que sobrou lá é decisão sobre
/// estado, que vale nas duas plataformas.
class RecoveryDisk {
  RecoveryDisk({
    WavHeaderRepair? wavRepair,
    DocumentsPathResolver? documentsPath,
  }) : _wavRepair = wavRepair ?? const WavHeaderRepair(),
       _documentsPath =
           documentsPath ??
           (() async => (await getApplicationDocumentsDirectory()).path);

  final WavHeaderRepair _wavRepair;
  final DocumentsPathResolver _documentsPath;

  /// Um arquivo de segmento que nunca chegou ao banco — o `_stopNative` que
  /// morreu entre gravar e registrar. Existe no disco e em lugar nenhum mais,
  /// então só uma listagem o encontra.
  Future<bool> hasOrphanSegmentFiles(String sessionId) async {
    final entries = await _list();
    if (entries.isEmpty) return false;
    final prefix = SegmentPaths.prefixFor(await _documentsPath(), sessionId);
    return entries.any(
      (e) => e is File && SegmentPaths.parseIndex(e.path, prefix) != null,
    );
  }

  Future<void> repairInFlightSegments(
    RecordingSession session,
    RecordingSessionRepository repo,
  ) async {
    final String documentsPath;
    try {
      documentsPath = await _documentsPath();
    } catch (_) {
      return;
    }

    final prefix = SegmentPaths.prefixFor(documentsPath, session.id);
    final candidates = <_OrphanedFile>[];
    for (final entry in await _list()) {
      if (entry is! File) continue;
      final index = SegmentPaths.parseIndex(entry.path, prefix);
      if (index == null) continue;
      if (index <= session.lastSegmentIndex) continue;
      candidates.add(_OrphanedFile(entry, index));
    }
    candidates.sort((a, b) => a.index.compareTo(b.index));

    for (final candidate in candidates) {
      final result = await _wavRepair.repair(candidate.file.path);
      if (result != null && result.duration > Duration.zero) {
        await repo.appendSegment(
          session.id,
          candidate.file.path,
          result.duration.inMilliseconds / 1000.0,
        );
      } else {
        try {
          await candidate.file.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<FileSystemEntity>> _list() async {
    try {
      return await Directory(await _documentsPath()).list().toList();
    } catch (_) {
      return const <FileSystemEntity>[];
    }
  }
}

class _OrphanedFile {
  const _OrphanedFile(this.file, this.index);
  final File file;
  final int index;
}
