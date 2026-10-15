import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/edit_transport_bar.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

Future<void> pumpBar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800) * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: EditTransportBar(
            isPlaying: false,
            position: const Duration(seconds: 25),
            duration: const Duration(seconds: 60),
            onPlayPause: () {},
          ),
        ),
      ),
    ),
  );
}

void expectLabelAtNaturalWidth(WidgetTester tester) {
  final label = find.byWidgetPredicate(
    (w) =>
        w is RichText && w.text.toPlainText().contains('00:25.00 / 01:00.00'),
  );
  final rich = tester.widget<RichText>(label);
  final natural = TextPainter(text: rich.text, textDirection: TextDirection.ltr)
    ..layout();
  expect(tester.getRect(label).width, closeTo(natural.width, 0.5));
  expect(tester.getRect(label).height, closeTo(natural.height, 0.5));
}

void main() {
  testWidgets('On a 360 dp phone the time label keeps its natural width beside '
      'the play button', (tester) async {
    await pumpBar(tester);

    expectLabelAtNaturalWidth(tester);
    expect(tester.takeException(), isNull);
  });
}
