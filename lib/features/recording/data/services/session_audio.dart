import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/database/app_database.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import 'audio_path_resolver.dart';

/// Whether [session] still holds audio somebody could get back — the finalized
/// recording it is anchored to, or one of [segmentPaths] the sources were left
/// in.
///
/// The question is deliberately "is the audio there", never "is the anchor
/// column set". A deliberate discard deletes the file and leaves the column
/// written (nothing clears it), so a non-null check would turn that path into
/// never-discards and the app would pile up dead session rows nothing cleans —
/// trading lost audio for permanent litter (ENG-521).
///
/// Both legs are resolved rather than stat'd literally, because the documents
/// container moves on reinstall/restore and an absolute path stored in an
/// earlier run would declare live audio gone. The anchor has been resolved
/// since ENG-521; the segments joined it in ENG-529, and they are the leg that
/// decides this predicate for a session that never finalized — the one whose
/// callers write the terminal status when it answers false.
Future<bool> sessionHoldsReachableAudio(
  RecordingSession session,
  List<String> segmentPaths,
) async {
  final anchor = session.finalizedAudioPath;
  if (anchor != null && await durableAudioExists(anchor)) return true;
  return (await resolveSegmentPaths(segmentPaths)).isNotEmpty;
}

/// O áudio que [address] nomeia ainda está lá?
///
/// É a mesma pergunta nas duas plataformas e tem duas respostas porque o
/// endereço durável é coisa diferente em cada uma (ENG-519, fatia 2). No
/// aparelho é um caminho de arquivo, que precisa ser resolvido porque o
/// contêiner muda de lugar. No navegador é a chave do armazenamento: ou está
/// no keyspace ou não está, e não existe outro diretório onde procurar.
///
/// [resolveRecordingPath] responde `null` no navegador de propósito — quem o
/// consome é a reprodução, que lá toca por URL e não por caminho — então a
/// pergunta vai direto à fachada [file_ops], que já é por plataforma.
Future<bool> durableAudioExists(String address) async {
  if (address.isEmpty) return false;
  if (kIsWeb) return file_ops.fileExists(address);
  return await resolveRecordingPath(address) != null;
}
