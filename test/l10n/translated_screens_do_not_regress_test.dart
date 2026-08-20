/// ENG-524: rede de regressão da auditoria.
///
/// O banner de gravações não salvas foi traduzido nos onze idiomas pelo
/// ENG-520, uma fatia antes desta. A auditoria mexe em vinte chaves espalhadas
/// por vários arquivos, e o jeito mais fácil de estragar tudo é reescrever, de
/// passagem, o que já estava certo. Os textos abaixo são literais de
/// propósito: comparar contra `AppLocalizations` seguiria passando depois de
/// uma reescrita, que é justamente o que este teste existe para pegar.
///
/// A data usada não é hoje nem ontem — o ramo de "ontem" pertence a
/// `format_yesterday`, que esta fatia traduz, e não deve entrar aqui.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/presentation/widgets/unsaved_recordings_banner.dart';

import '../support/text_scale.dart';

final _session = InterruptedSession(
  sessionId: 'session-0',
  genreId: 'gen_narrative',
  subcategoryId: 'sub_genealogy',
  totalDuration: const Duration(minutes: 3, seconds: 20),
  startedAt: DateTime(2026, 5, 1, 14, 30),
  segmentCount: 1,
);

Future<void> _pumpBanner(WidgetTester tester, String locale) => pumpAtTextScale(
  tester,
  locale: Locale(locale),
  child: UnsavedRecordingsBanner(sessions: [_session], onReview: () {}),
);

void main() {
  final expected = <String, List<String>>{
    'ar': ['مراجعة', 'تسجيل واحد غير محفوظ'],
    'zh': ['查看', '1 条录音未保存'],
    'sw': ['Kagua', 'Rekodi 1 haijahifadhiwa'],
  };

  group('a tela de gravações não salvas continua como o ENG-520 a deixou', () {
    expected.forEach((tag, texts) {
      testWidgets('$tag mantém os textos traduzidos', (tester) async {
        await _pumpBanner(tester, tag);

        for (final text in texts) {
          expect(
            find.text(text),
            findsOneWidget,
            reason: '"$text" mudou em $tag — esta fatia não devia tocar nele',
          );
        }
      });
    });
  });
}
