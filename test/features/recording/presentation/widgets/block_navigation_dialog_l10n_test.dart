/// ENG-524: o diálogo que barra a saída durante uma gravação é o aviso mais
/// caro do app — ele diz que sair apaga a gravação de vez. É a única das telas
/// auditadas em que as três chaves estão em inglês nos onze idiomas, português
/// inclusive.
///
/// Idiomas estruturalmente diferentes: árabe (direita para a esquerda), chinês
/// (sem flexão de número) e híndi (devanágari).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/block_navigation_dialog.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_ar.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_hi.dart';
import 'package:oral_collector/l10n/app_localizations_zh.dart';

import '../../../../support/text_scale.dart';

/// O diálogo é aberto por uma função, não por um widget — o botão abaixo é o
/// gatilho mínimo para colocá-lo na tela.
class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(
      onPressed: () => showBlockNavigationDialog(context),
      child: const Text('open'),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester, String locale) async {
  await pumpAtTextScale(tester, locale: Locale(locale), child: const _Opener());
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final en = AppLocalizationsEn();

  final locales = <String, AppLocalizations>{
    'ar': AppLocalizationsAr(),
    'zh': AppLocalizationsZh(),
    'hi': AppLocalizationsHi(),
  };

  group('o aviso de sair durante a gravação não fala inglês', () {
    locales.forEach((tag, l10n) {
      testWidgets('$tag mostra título, corpo e ação no próprio idioma', (
        tester,
      ) async {
        await _openDialog(tester, tag);

        expect(find.text(en.recording_blockNavTitle), findsNothing);
        expect(find.text(en.recording_blockNavMessage), findsNothing);
        expect(find.text(en.recording_blockNavDiscardAndLeave), findsNothing);

        expect(find.text(l10n.recording_blockNavTitle), findsOneWidget);
        expect(find.text(l10n.recording_blockNavMessage), findsOneWidget);
        expect(
          find.text(l10n.recording_blockNavDiscardAndLeave),
          findsOneWidget,
        );
      });
    });
  });
}
