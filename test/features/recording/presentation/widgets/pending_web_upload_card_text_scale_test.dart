// ENG-427: the card's body grew a second version and both sentences are longer
// than the one they replace, in every locale. main.dart caps the system text
// scale at 2.0x, so 2.0x on the narrowest phone that ships (320dp) is the case
// that decides whether the new copy fits.
//
// The card is pumped as the recordings list renders it — straight into the
// scroll view, with only the horizontal margin the card carries itself. That
// margin is the whole of the padding it gets on the real screen, so measuring
// it any wider would be measuring a card that does not ship.
//
// All eleven shipped locales are in the matrix rather than the usual French +
// Arabic pair: the new body is longer than the one it replaces in every
// language, so which one runs out of room first is not a safe guess. No font is
// loaded in `flutter_test`, so every glyph measures one em — roughly 1.7x wider
// than real text, which makes this gate conservative rather than lax.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pending_web_upload_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

const _narrowPhone = Size(320, 640);

/// Tok Pisin has no `GlobalMaterialLocalizations`, and the framework's warning
/// about that reaches a test the same way an overflow does. Draining it first
/// keeps the locale in the matrix instead of dropping the one language nobody
/// else measures.
void expectFits(WidgetTester tester) {
  final thrown = tester.takeException();
  if (thrown is String && thrown.startsWith('Warning:')) {
    expect(tester.takeException(), isNull);
    return;
  }
  expect(thrown, isNull);
}

LocalRecordingEntity _entity({int uploadedBytes = 0}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Histórias de pesca contadas pelo mais velho da aldeia',
  durationSeconds: 900,
  fileSizeBytes: 48 * 1024 * 1024,
  format: 'webm',
  localFilePath: 'web_record_1755600000000.webm',
  uploadStatus: 'web_uploading',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 8, 19),
  createdAt: DateTime(2026, 8, 19),
  retryCount: 0,
  uploadedBytes: uploadedBytes,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required double scale,
  required Locale locale,
  required bool hasStoredAudio,
  int uploadedBytes = 0,
}) => pumpAtTextScale(
  tester,
  scale: scale,
  locale: locale,
  size: _narrowPhone,
  child: SingleChildScrollView(
    child: PendingWebUploadCard(
      recording: _entity(uploadedBytes: uploadedBytes),
      hasStoredAudio: hasStoredAudio,
      isResuming: false,
      onResume: () {},
      onDiscard: () {},
    ),
  ),
);

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final hasStoredAudio in const [true, false]) {
      final audio = hasStoredAudio ? 'stored audio' : 'no stored audio';
      testWidgets(
        'fits a 320dp phone at 2.0x in ${locale.languageCode} with $audio',
        (tester) async {
          await _pumpCard(
            tester,
            scale: 2.0,
            locale: locale,
            hasStoredAudio: hasStoredAudio,
          );

          expectFits(tester);
        },
      );
    }
  }

  testWidgets('fits at 2.0x with the progress row showing', (tester) async {
    await _pumpCard(
      tester,
      scale: 2.0,
      locale: const Locale('fr'),
      hasStoredAudio: true,
      uploadedBytes: 12 * 1024 * 1024,
    );

    expectFits(tester);
  });
}
