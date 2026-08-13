/// ENG-410: the gate that stops the next translation debt.
///
/// Two debts reached `dev` the same way — a change edited `app_en.arb` and
/// `app_pt.arb`, wrote the gap down somewhere, and shipped. Nothing failed:
/// `flutter gen-l10n` fills a missing key with the English template text, and
/// `l10n.yaml` sets no `untranslated-messages-file`, so no report is produced
/// either. This test is the missing failure.
///
/// It is the one file here that reads the ARBs instead of the strings the app
/// renders. That is deliberate and unavoidable: `AppLocalizations` exposes
/// getters, not a key list, and a missing key is indistinguishable at runtime
/// from one translated identically to English. Whole-catalogue coverage can
/// only be asserted over the catalogue.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/l10n/supported_locales.dart';

Set<String> _messageKeys(String languageCode) {
  final file = File('lib/l10n/app_$languageCode.arb');
  expect(
    file.existsSync(),
    isTrue,
    reason: '${file.path} is missing for supported locale $languageCode',
  );
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('every supported locale translates the whole template', () {
    final template = _messageKeys('en');

    for (final locale in supportedLocales) {
      final keys = _messageKeys(locale.languageCode);

      final missing = template.difference(keys).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            '${missing.length} key(s) have no ${locale.languageCode} '
            'translation, so the app shows English there: $missing',
      );

      final orphan = keys.difference(template).toList()..sort();
      expect(
        orphan,
        isEmpty,
        reason:
            '${orphan.length} key(s) in app_${locale.languageCode}.arb are not '
            'in the template and nothing reads them: $orphan',
      );
    }
  });
}
