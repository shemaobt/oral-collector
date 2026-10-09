// ENG-524: gate de paridade de tradução.
//
// Falha quando uma chave de um idioma tem valor idêntico ao do template inglês
// sem estar na lista de coincidências aceitas abaixo. Duas fatias seguidas
// descobriram texto em inglês em telas traduzidas por acaso; este script existe
// para que a próxima seja descoberta pelo CI.
//
// Uso (a partir da raiz do pacote):
//   dart run tool/check_l10n_parity.dart          # ou sh scripts/check_l10n_parity.sh
//
// Para aceitar uma coincidência nova: acrescente a chave em [_accepted] com os
// idiomas em que ela é legítima e o motivo em uma linha. O motivo é a única
// coisa que separa uma auditoria de uma lista de silenciamento — escreva por
// que aquela palavra é a palavra daquela língua, não que "é só um rótulo".

import 'dart:convert';
import 'dart:io';

/// Coincidências legítimas: chave -> (idiomas onde o valor coincide com o
/// inglês, motivo). Um idioma fora desta lista é violação, mesmo que a chave
/// esteja listada — "Genre" é francês, não coreano.
const Map<String, ({List<String> locales, String reason})> _accepted = {
  // Marca.
  'appTitle': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Nome do produto; não se traduz.',
  ),
  'auth_oralCollector': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Nome do produto; não se traduz.',
  ),

  // Endônimos: o seletor mostra cada idioma escrito na própria língua, então o
  // valor é por definição o mesmo em todos os arquivos.
  'locale_arabic': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (العربية).',
  ),
  'locale_bahasa': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua.',
  ),
  'locale_chinese': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (中文).',
  ),
  'locale_english': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua.',
  ),
  'locale_french': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (Français).',
  ),
  'locale_hindi': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (हिन्दी).',
  ),
  'locale_korean': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (한국어).',
  ),
  'locale_portuguese': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (Português).',
  ),
  'locale_spanish': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (Español).',
  ),
  'locale_swahili': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua (Kiswahili).',
  ),
  'locale_tokPisin': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Endônimo: o idioma escrito na própria língua.',
  ),

  // Subtítulos do seletor: o nome do idioma na língua de quem lê.
  'locale_hindiSub': (
    locales: ['es', 'fr', 'id', 'pt'],
    reason: '"Hindi" se escreve assim nestas quatro línguas.',
  ),
  'locale_swahiliSub': (
    locales: ['fr', 'id'],
    reason:
        '"Swahili" se escreve assim em francês e indonésio '
        '(es "Suajili" e pt "Suaíli" diferem, como se espera).',
  ),
  'locale_tokPisinSub': (
    locales: ['es', 'fr', 'id', 'pt', 'sw', 'tpi'],
    reason: 'Nome próprio do idioma; não tem exônimo nestas línguas.',
  ),

  // Sem palavra a traduzir.
  'recording_serviceNotificationBody': (
    locales: ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'],
    reason: 'Só marcadores e um bullet: "{elapsed} • {genre}".',
  ),
  'home_greetingWithName': (
    locales: ['es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi'],
    reason:
        'Só marcadores e a vírgula ASCII; ar e zh usam a própria '
        'pontuação e por isso diferem.',
  ),
  'recording_uploadSpeed': (
    locales: ['es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi'],
    reason: '"s" é o símbolo SI de segundo; ar e zh optaram por localizar.',
  ),

  // Cognatos e empréstimos.
  'action_actions': (locales: ['fr'], reason: '"Actions" é a grafia francesa.'),
  'admin_cleaningActions': (
    locales: ['fr'],
    reason: '"Actions" é a grafia francesa.',
  ),
  'admin_genres': (locales: ['fr'], reason: '"Genres" é a grafia francesa.'),
  'home_genres': (locales: ['fr'], reason: '"Genres" é a grafia francesa.'),
  'filters_sectionGenre': (
    locales: ['fr', 'id'],
    reason: '"Genre" é palavra francesa e empréstimo dicionarizado no KBBI.',
  ),
  'genre_title': (
    locales: ['fr', 'id'],
    reason: '"Genre" é palavra francesa e empréstimo dicionarizado no KBBI.',
  ),
  'moveCategory_genre': (
    locales: ['fr', 'id'],
    reason: '"Genre" é palavra francesa e empréstimo dicionarizado no KBBI.',
  ),
  'admin_cleaningFormat': (
    locales: ['fr', 'id'],
    reason: '"Format" é palavra francesa e empréstimo dicionarizado no KBBI.',
  ),
  'detail_format': (
    locales: ['fr', 'id'],
    reason: '"Format" é palavra francesa e empréstimo dicionarizado no KBBI.',
  ),
  'profile_administration': (
    locales: ['fr'],
    reason: '"Administration" é a grafia francesa.',
  ),
  'profile_invitations': (
    locales: ['fr'],
    reason: '"Invitations" é a grafia francesa.',
  ),
  'project_description': (
    locales: ['fr'],
    reason: '"Description" é a grafia francesa.',
  ),
  'recording_description': (
    locales: ['fr'],
    reason: '"Description" é a grafia francesa.',
  ),
  'recording_pause': (locales: ['fr'], reason: '"Pause" é palavra francesa.'),
  'sub_dialogue': (locales: ['fr'], reason: '"Dialogue" é a grafia francesa.'),
  'sub_exhortation': (
    locales: ['fr'],
    reason: '"Exhortation" e "Sermon" são as grafias francesas.',
  ),
  'trim_segments': (locales: ['fr'], reason: '"Segments" é a grafia francesa.'),
  'register_ceremonial': (
    locales: ['es'],
    reason: '"Ceremonial" é a grafia espanhola.',
  ),
  'nav_admin': (
    locales: ['es', 'fr', 'id', 'pt', 'tpi'],
    reason: '"Admin" é a abreviação corrente nestas cinco línguas.',
  ),
  'profile_adminBadge': (
    locales: ['es', 'fr', 'id', 'pt', 'tpi'],
    reason: '"Admin" é a abreviação corrente nestas cinco línguas.',
  ),
  'common_ok': (
    locales: ['fr', 'id', 'pt'],
    reason:
        '"OK" é interjeição internacional; es/sw/tpi traduziram, o que '
        'não torna "OK" errado nestas três.',
  ),
  'recording_statusLocal': (
    locales: ['es', 'fr', 'pt'],
    reason: '"Local" é palavra destas três línguas.',
  ),
  'trim_volume': (
    locales: ['fr', 'id', 'pt'],
    reason: '"Volume" é palavra destas três línguas.',
  ),
  'detail_status': (
    locales: ['id', 'pt'],
    reason: '"Status" é dicionarizado em português e está no KBBI.',
  ),
  'profile_status': (
    locales: ['id', 'pt'],
    reason: '"Status" é dicionarizado em português e está no KBBI.',
  ),
  'profile_offline': (
    locales: ['id', 'pt'],
    reason: 'Empréstimo corrente em português e indonésio.',
  ),
  'profile_online': (
    locales: ['id', 'pt'],
    reason: 'Empréstimo corrente em português e indonésio.',
  ),

  // Ambíguas, declaradas como tal (ENG-524). Todas em indonésio: o empréstimo
  // já é ortograficamente indonésio, então adaptá-lo como sw e tpi fizeram
  // produziria a mesma palavra. A alternativa nativa fica registrada.
  'classify_register': (
    locales: ['id'],
    reason:
        'Ambígua: o KBBI registra "register" como termo de linguística '
        '(ragam bahasa). Alternativa nativa: "Ragam".',
  ),
  'recording_inputSource': (
    locales: ['id'],
    reason: 'Ambígua: "input" está no KBBI. Alternativa nativa: "Masukan".',
  ),
  'action_split': (
    locales: ['id'],
    reason:
        'Ambígua: "edit" está no KBBI e é o rótulo padrão nas UIs '
        'indonésias. Alternativa nativa: "Sunting".',
  ),
};

const _arbDir = 'lib/l10n';
const _template = 'en';
const _locales = ['ar', 'es', 'fr', 'hi', 'id', 'ko', 'pt', 'sw', 'tpi', 'zh'];

Map<String, Object?> _readArb(String locale) =>
    jsonDecode(File('$_arbDir/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

void main() {
  final template = _readArb(_template);
  final keys = template.keys.where((k) => !k.startsWith('@')).toList();

  final violations = <(String locale, String key)>[];
  final seen = <String, Set<String>>{};

  for (final locale in _locales) {
    final translated = _readArb(locale);
    for (final key in keys) {
      if (translated[key] != template[key]) continue;
      seen.putIfAbsent(key, () => {}).add(locale);
      if (_accepted[key]?.locales.contains(locale) ?? false) continue;
      violations.add((locale, key));
    }
  }

  final stale = <String>[];
  _accepted.forEach((key, entry) {
    final actual = seen[key] ?? const <String>{};
    final gone = entry.locales.where((l) => !actual.contains(l)).toList();
    if (gone.isNotEmpty) stale.add('$key: ${gone.join(", ")}');
  });

  if (stale.isNotEmpty) {
    stdout.writeln(
      'Aviso: entradas aceitas que já não coincidem com o inglês '
      '(traduzidas desde então — podem sair da lista):',
    );
    for (final entry in stale) {
      stdout.writeln('  $entry');
    }
    stdout.writeln('');
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'l10n parity: nenhuma chave em inglês fora da lista de coincidências '
      'aceitas (${_accepted.length} aceitas, ${keys.length} chaves × '
      '${_locales.length} idiomas).',
    );
    return;
  }

  stderr.writeln(
    'Chaves idênticas ao template inglês e fora da lista de coincidências '
    'aceitas:',
  );
  for (final (locale, key) in violations) {
    stderr.writeln('  $locale/$key: ${jsonEncode(template[key])}');
  }
  stderr.writeln('');
  stderr.writeln(
    'Traduza a chave, ou — se a coincidência for legítima — acrescente-a a '
    '_accepted em tool/check_l10n_parity.dart com o motivo em uma linha.',
  );
  exitCode = 1;
}
