/// Caminhos isentos de `avoid_raw_print`: a fachada de logging sob
/// `lib/core/observability/` (ADR-0010) é o único lugar legítimo para um
/// eventual fallback de baixo nível, e arquivos sob `test/` podem usar
/// `print` / `debugPrint` ao depurar (ENG-183, mesma convenção de
/// isColorLintExempt). Casa o segmento `/test/`, não o sufixo `_test.dart`.
bool isRawPrintExempt(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/lib/core/observability/') ||
      normalized.contains('/test/');
}
