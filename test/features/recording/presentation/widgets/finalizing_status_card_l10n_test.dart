/// ENG-524: o cartão de finalização é a tela que mais concentra chaves em
/// inglês — a frase de tranquilização, o aviso de não fechar e o rótulo curto
/// de cada etapa. Quem para uma gravação vê esse cartão; se ele fala inglês,
/// a promessa da tela anterior (feita no idioma da pessoa) é quebrada
/// exatamente no momento em que ela está esperando.
///
/// Os idiomas são escolhidos por serem estruturalmente diferentes entre si:
/// árabe (escrita da direita para a esquerda), chinês (sem flexão de número) e
/// híndi (devanágari, fora dessas duas famílias).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_status_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_ar.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_hi.dart';
import 'package:oral_collector/l10n/app_localizations_zh.dart';

import '../../../../support/text_scale.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required String locale,
  required FinalizationStage stage,
}) => pumpAtTextScale(
  tester,
  locale: Locale(locale),
  child: FinalizingStatusCard(stage: stage),
);

void main() {
  final en = AppLocalizationsEn();

  final locales = <String, AppLocalizations>{
    'ar': AppLocalizationsAr(),
    'zh': AppLocalizationsZh(),
    'hi': AppLocalizationsHi(),
  };

  final stages = <FinalizationStage, String Function(AppLocalizations)>{
    FinalizationStage.finalizing: (l) => l.recording_stageShortFinalizing,
    FinalizationStage.combiningSegments: (l) => l.recording_stageShortCombining,
    FinalizationStage.compressingAudio: (l) =>
        l.recording_stageShortCompressing,
  };

  group('o cartão de finalização não fala inglês', () {
    locales.forEach((tag, l10n) {
      testWidgets('$tag mostra a tranquilização no próprio idioma', (
        tester,
      ) async {
        await _pumpCard(
          tester,
          locale: tag,
          stage: FinalizationStage.finalizing,
        );

        expect(find.text(en.recording_processingYourAudio), findsNothing);
        expect(find.text(en.recording_dontCloseSaveNext), findsNothing);

        expect(find.text(l10n.recording_processingYourAudio), findsOneWidget);
        expect(find.text(l10n.recording_dontCloseSaveNext), findsOneWidget);
      });

      stages.forEach((stage, label) {
        testWidgets('$tag mostra o rótulo de ${stage.name} no próprio idioma', (
          tester,
        ) async {
          await _pumpCard(tester, locale: tag, stage: stage);

          expect(find.text(label(en)), findsNothing);
          expect(find.text(label(l10n)), findsOneWidget);
        });
      });
    });
  });
}
