import 'file_import_entry.dart';

/// Processa cada entrada ainda não concluída chamando [saveOne], registrando
/// cada sucesso em [completedIds]. Assim, um retry após falha parcial reprocessa
/// apenas as entradas pendentes, sem reenviar as já concluídas.
Future<void> runImportSave(
  List<FileImportEntry> entries,
  Set<String> completedIds,
  Future<void> Function(FileImportEntry entry) saveOne, {
  void Function(int completedCount)? onProgress,
}) async {
  for (final entry in entries) {
    if (completedIds.contains(entry.id)) continue;
    await saveOne(entry);
    completedIds.add(entry.id);
    onProgress?.call(completedIds.length);
  }
}
