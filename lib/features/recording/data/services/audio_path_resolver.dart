import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/file_ops.dart' as file_ops;

Future<String?> resolveRecordingPath(String storedPath) async {
  if (kIsWeb) return null;
  if (storedPath.isEmpty) return null;

  if (await file_ops.fileExists(storedPath)) return storedPath;

  final docsDir = await getApplicationDocumentsDirectory();
  return _resolveUnderDocuments(storedPath, docsDir.path);
}

/// Os segmentos de uma sessão, resolvidos pelo mesmo critério da âncora e na
/// ordem em que foram gravados (ENG-529).
///
/// Sem isto os dois lugares que montam a lista de segmentos válidos filtravam
/// pelo caminho **literal**, e uma sessão sem âncora declarava ausentes todos
/// os segmentos depois de o contêiner mudar de lugar — com os arquivos ali. Um
/// caminho que não resolve simplesmente não entra na lista, que é como a
/// ausência de verdade continua sendo ausência.
///
/// A consulta ao diretório de documentos é paga **uma vez por lista**, não uma
/// por segmento: uma gravação longa tem dezenas de segmentos, e cada consulta
/// é uma ida ao canal de plataforma.
Future<List<String>> resolveSegmentPaths(List<String> storedPaths) async {
  if (kIsWeb) return const [];

  final resolved = <String>[];
  String? documentsPath;
  for (final storedPath in storedPaths) {
    if (storedPath.isEmpty) continue;
    if (await file_ops.fileExists(storedPath)) {
      resolved.add(storedPath);
      continue;
    }
    documentsPath ??= (await getApplicationDocumentsDirectory()).path;
    final alternative = await _resolveUnderDocuments(storedPath, documentsPath);
    if (alternative != null) resolved.add(alternative);
  }
  return resolved;
}

/// Onde o arquivo estaria se o contêiner tivesse mudado de lugar: mesmo nome,
/// diretório de documentos atual.
Future<String?> _resolveUnderDocuments(
  String storedPath,
  String documentsPath,
) async {
  final fileName = p.basename(storedPath);
  final resolved = '$documentsPath/$fileName';
  if (await file_ops.fileExists(resolved)) return resolved;

  final inSubdir = '$documentsPath/recordings/$fileName';
  if (await file_ops.fileExists(inSubdir)) return inSubdir;

  return null;
}
