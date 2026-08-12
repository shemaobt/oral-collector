/// ENG-410: the pending-edit warnings have to arrive in the reader's language.
///
/// These five strings tell someone that an edit is still waiting for a
/// connection, or that it will never leave the phone unless they act. Landing
/// them in English in nine of the eleven locales means they fail exactly for
/// the people who most depend on them.
///
/// Comparing each locale's text against the English one is the only honest way
/// to tell a translation from a silent fallback: `flutter gen-l10n` fills a
/// missing key with the template text and leaves no trace of having done so,
/// so a getter that merely returns something non-empty proves nothing.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/l10n/supported_locales.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

final _marks = <String, String Function(AppLocalizations)>{
  'recording_metadataSyncPending': (l) => l.recording_metadataSyncPending,
  'recording_metadataSyncForbidden': (l) => l.recording_metadataSyncForbidden,
  'recording_metadataSyncConflict': (l) => l.recording_metadataSyncConflict,
  'recording_metadataSyncExhausted': (l) => l.recording_metadataSyncExhausted,
  'detail_metadataSync': (l) => l.detail_metadataSync,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every supported locale has its own pending-edit warnings', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final locale in supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);

      for (final entry in _marks.entries) {
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
              'the key is missing from app_${locale.languageCode}.arb and '
              'gen-l10n fell back to the template',
        );
      }
    }
  });
}
