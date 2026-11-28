/// Caminhos isentos de `avoid_raw_dialog`: o próprio kit de perguntas, o
/// auxiliar de folhas e arquivos sob `test/`. Casa o segmento `/test/`, não o sufixo `_test.dart`.
bool isRawDialogExempt(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.endsWith('/lib/shared/widgets/app_question.dart') ||
      normalized.endsWith('/lib/shared/widgets/app_sheet.dart') ||
      normalized.contains('/test/');
}
