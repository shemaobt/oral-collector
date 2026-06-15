/// Arquivos sob `lib/core/theme/` definem os design tokens e podem usar
/// `Color(...)` / `Colors.*` diretamente (ADR-0002, ADR-0007).
bool isThemeFile(String path) =>
    path.replaceAll(r'\', '/').contains('/lib/core/theme/');
