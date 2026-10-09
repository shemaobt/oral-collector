/// ENG-520: o ENG-518 fez a tela de gravações não salvas virar destino normal —
/// o diálogo de saída promete, no idioma da pessoa, que a gravação pode ser
/// terminada ali. A tela tem de cumprir a promessa no mesmo idioma.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/presentation/widgets/unsaved_recordings_banner.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_ar.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_pt.dart';
import 'package:oral_collector/l10n/app_localizations_sw.dart';
import 'package:oral_collector/l10n/app_localizations_zh.dart';

import '../../../../support/text_scale.dart';

List<InterruptedSession> _sessions(int count) => List.generate(
  count,
  (i) => InterruptedSession(
    sessionId: 'session-$i',
    genreId: 'gen_narrative',
    subcategoryId: 'sub_genealogy',
    totalDuration: const Duration(minutes: 3, seconds: 20),
    startedAt: DateTime(2026, 8, 20, 14, 30),
    segmentCount: 1,
  ),
);

Future<void> _pumpBanner(
  WidgetTester tester, {
  required String locale,
  required int count,
}) => pumpAtTextScale(
  tester,
  locale: Locale(locale),
  child: UnsavedRecordingsBanner(sessions: _sessions(count), onReview: () {}),
);

/// O texto que sobra quando se tiram os dígitos — é a *forma* da frase, o que
/// muda entre categorias de plural. Dígitos podem sair em qualquer sistema de
/// numeração, então a classe Unicode, não `[0-9]`.
String _shape(String text) =>
    text.replaceAll(RegExp(r'\p{Nd}', unicode: true), '').trim();

String _counterText(WidgetTester tester, AppLocalizations l10n, int count) {
  final finder = find.text(l10n.recovery_unsavedCount(count));
  expect(
    finder,
    findsOneWidget,
    reason: 'o contador tem de sair na mensagem do próprio idioma',
  );
  final text = tester.widget<Text>(finder).data!;
  // Sem isto, uma língua cuja regra de plural coincide com a do inglês passaria
  // no teste de forma sem ter sido traduzida.
  expect(text, isNot(AppLocalizationsEn().recovery_unsavedCount(count)));
  return text;
}

void main() {
  final en = AppLocalizationsEn();

  group('a tela não fala inglês', () {
    final locales = {
      'ar': AppLocalizationsAr(),
      'zh': AppLocalizationsZh(),
      'sw': AppLocalizationsSw(),
    };

    locales.forEach((tag, l10n) {
      testWidgets('$tag não mostra a copy inglesa', (tester) async {
        await _pumpBanner(tester, locale: tag, count: 1);

        expect(find.text(en.recovery_review), findsNothing);
        expect(find.text(en.recovery_unsavedCount(1)), findsNothing);

        expect(find.text(l10n.recovery_review), findsOneWidget);
        expect(find.text(l10n.recovery_unsavedCount(1)), findsOneWidget);
      });
    });
  });

  group('o contador conta certo', () {
    testWidgets('o árabe separa uma, poucas e muitas', (tester) async {
      final l10n = AppLocalizationsAr();

      await _pumpBanner(tester, locale: 'ar', count: 1);
      final one = _shape(_counterText(tester, l10n, 1));

      await _pumpBanner(tester, locale: 'ar', count: 3);
      final few = _shape(_counterText(tester, l10n, 3));

      await _pumpBanner(tester, locale: 'ar', count: 11);
      final many = _shape(_counterText(tester, l10n, 11));

      expect(one, isNot(few));
      expect(few, isNot(many));
      expect(one, isNot(many));
    });

    testWidgets('o chinês usa uma forma só', (tester) async {
      final l10n = AppLocalizationsZh();

      await _pumpBanner(tester, locale: 'zh', count: 1);
      final one = _shape(_counterText(tester, l10n, 1));

      await _pumpBanner(tester, locale: 'zh', count: 3);
      final several = _shape(_counterText(tester, l10n, 3));

      expect(one, several);
    });

    testWidgets('o suaíli separa uma de várias', (tester) async {
      final l10n = AppLocalizationsSw();

      await _pumpBanner(tester, locale: 'sw', count: 1);
      final one = _shape(_counterText(tester, l10n, 1));

      await _pumpBanner(tester, locale: 'sw', count: 3);
      final several = _shape(_counterText(tester, l10n, 3));

      expect(one, isNot(several));
      expect(find.textContaining('3'), findsWidgets);
    });
  });

  group('o português não regride', () {
    testWidgets('continua em português com uma e com várias', (tester) async {
      final l10n = AppLocalizationsPt();

      await _pumpBanner(tester, locale: 'pt', count: 1);
      expect(find.text(l10n.recovery_unsavedCount(1)), findsOneWidget);
      expect(find.text(l10n.recovery_review), findsOneWidget);
      expect(find.text(en.recovery_unsavedCount(1)), findsNothing);

      await _pumpBanner(tester, locale: 'pt', count: 4);
      expect(find.text(l10n.recovery_unsavedCount(4)), findsOneWidget);
    });
  });
}
