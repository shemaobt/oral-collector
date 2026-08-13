/// ENG-410: the clear-cache dialog has to speak the reader's language too.
///
/// Three keys, not one: the confirmation body, the settings subtitle, and the
/// plural result line that ENG-407 added when clearing the cache stopped
/// deleting everything and started keeping what has not been uploaded yet.
///
/// The plural key is exercised at more than one count because a translation
/// can define one branch and leave another in English, and nothing about that
/// breaks compilation. The counts below cover the six categories Arabic
/// distinguishes (zero, one, two, few, many, other), so a locale that copied
/// the English two-branch structure is caught at the count where it matters.
///
/// What this file cannot check: whether the two rewritten keys actually
/// describe the post-ENG-407 behaviour — that they delete only the local
/// copies the server already has, and keep the rest. No test knows that; it is
/// human review, and the PR lists the texts so it can happen.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/l10n/supported_locales.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

const _counts = [0, 1, 2, 3, 11, 100];

final _plain = <String, String Function(AppLocalizations)>{
  'profile_clearCacheMessage': (l) => l.profile_clearCacheMessage,
  'profile_clearCacheSubtitle': (l) => l.profile_clearCacheSubtitle,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every supported locale has its own clear-cache dialog text', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final locale in supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);

      for (final entry in _plain.entries) {
        final text = entry.value(l10n);

        expect(
          text.trim(),
          isNotEmpty,
          reason: '${entry.key} is empty in ${locale.languageCode}',
        );

        if (locale.languageCode == 'en') continue;

        expect(
          text,
          isNot(entry.value(english)),
          reason:
              '${entry.key} in ${locale.languageCode} is the English text — '
              'gen-l10n fell back to the template',
        );
      }
    }
  });

  test('the kept-recordings line is translated at every count', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final locale in supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);

      for (final count in _counts) {
        final text = l10n.profile_cacheClearedKept(count);

        expect(
          text.trim(),
          isNotEmpty,
          reason:
              'profile_cacheClearedKept is empty at count=$count in '
              '${locale.languageCode}',
        );

        if (locale.languageCode == 'en') continue;

        expect(
          text,
          isNot(english.profile_cacheClearedKept(count)),
          reason:
              'profile_cacheClearedKept at count=$count in '
              '${locale.languageCode} is the English text — either the key is '
              'missing or that plural branch was left untranslated',
        );
      }
    }
  });
}
