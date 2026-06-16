/// Caminhos isentos das regras de cor: arquivos sob `lib/core/theme/` definem os
/// design tokens, e arquivos sob `test/` (fixtures, golden setups) podem usar
/// `Color(...)` / `Colors.*` diretamente (ADR-0002, ADR-0007; `test/` isento em
/// ENG-183). Casa o segmento `/test/`, não o sufixo `_test.dart`.
bool isColorLintExempt(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/lib/core/theme/') ||
      normalized.contains('/test/');
}
