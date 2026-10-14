/// ENG-66: o piso de um segmento no editor de trim é tempo, não porcentagem.
///
/// Todos os testes observam a borda pública de [TrimWaveform]: a lista de
/// pontos de corte que ele emite por `onSplitPointsChanged` depois de um gesto
/// real. Nenhum lê campo privado, constante ou colaborador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/excluded_range.dart';
import 'package:oral_collector/features/recording/presentation/widgets/trim_waveform.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

const double _kWidth = 400;

/// Monta o widget com a duração e o zoom dados, realimentando as emissões no
/// próprio `splitPoints` — é assim que a tela real se comporta (o notifier
/// devolve a lista nova e o widget reconstrói).
Widget _harness({
  required Duration totalDuration,
  required List<double> initialSplits,
  required List<List<double>> emissions,
  double zoom = 1.0,
  double panFraction = 0.0,
  List<ExcludedRange> excludedRanges = const [],
}) {
  var splits = initialSplits;
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: _kWidth,
          child: StatefulBuilder(
            builder: (context, setInner) => TrimWaveform(
              bars: List<double>.filled(64, 0.5),
              splitPoints: splits,
              excludedRanges: excludedRanges,
              totalDuration: totalDuration,
              zoom: zoom,
              panFraction: panFraction,
              onSplitPointsChanged: (next) {
                emissions.add(next);
                setInner(() => splits = next);
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _waveformRect(WidgetTester tester) {
  final box = tester.renderObject<RenderBox>(find.byType(TrimWaveform));
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Ponto na tela correspondente a [seconds] da gravação, respeitando zoom/pan.
Offset _atSeconds(
  WidgetTester tester,
  Duration total,
  double seconds, {
  double zoom = 1.0,
  double panFraction = 0.0,
}) {
  final rect = _waveformRect(tester);
  final fullFraction = seconds / (total.inMilliseconds / 1000.0);
  final localX = (fullFraction - panFraction) * zoom * rect.width;
  return Offset(rect.left + localX, rect.center.dy);
}

/// Converte um ponto de corte (fração) de volta para segundos.
double _seconds(double fraction, Duration total) =>
    fraction * total.inMilliseconds / 1000.0;

void main() {
  const threeMinutes = Duration(minutes: 3);
  const thirtyThree = Duration(seconds: 33);

  testWidgets(
    'toque longo a meio segundo do início cria um corte numa gravação de 3 '
    'minutos',
    (tester) async {
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: threeMinutes,
          initialSplits: const [0.5],
          emissions: emissions,
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPressAt(_atSeconds(tester, threeMinutes, 0.5));
      await tester.pumpAndSettle();

      expect(
        emissions,
        hasLength(1),
        reason: 'o gesto deveria emitir exatamente uma lista nova',
      );
      final added = emissions.single.where((p) => p != 0.5).toList();
      expect(
        added,
        hasLength(1),
        reason: 'esperava um corte novo, além do 0.5',
      );
      expect(_seconds(added.single, threeMinutes), closeTo(0.5, 0.05));
    },
  );

  testWidgets(
    'o mesmo meio segundo é aceito em 33 s e em 3 minutos: o piso não cresce '
    'com a duração',
    (tester) async {
      final accepted = <Duration, double>{};

      for (final total in [thirtyThree, threeMinutes]) {
        final emissions = <List<double>>[];
        await tester.pumpWidget(
          _harness(
            totalDuration: total,
            initialSplits: const [],
            emissions: emissions,
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPressAt(_atSeconds(tester, total, 0.5));
        await tester.pumpAndSettle();

        expect(
          emissions,
          hasLength(1),
          reason: 'meio segundo deveria ser aceito numa gravação de $total',
        );
        accepted[total] = _seconds(emissions.single.single, total);
      }

      expect(accepted[thirtyThree], closeTo(0.5, 0.05));
      expect(accepted[threeMinutes], closeTo(0.5, 0.05));
    },
  );

  testWidgets(
    'arrastar a alça encurta o primeiro segmento até meio segundo em vez de '
    'ser limitada de volta',
    (tester) async {
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: threeMinutes,
          initialSplits: const [0.5],
          emissions: emissions,
        ),
      );
      await tester.pumpAndSettle();

      final from = _atSeconds(tester, threeMinutes, 90);
      final to = _atSeconds(tester, threeMinutes, 0.5);

      // `dragFrom` porque ele trata o touch slop: um único `moveTo` grande
      // atravessa o slop e nunca produz o `onScaleUpdate` seguinte, então o
      // arraste não chegaria ao widget.
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();

      expect(emissions, isNotEmpty, reason: 'o arraste deveria emitir');
      final last = emissions.last;
      expect(last, hasLength(1));
      expect(_seconds(last.single, threeMinutes), closeTo(0.5, 0.05));
    },
  );

  testWidgets(
    'o piso continua existindo: 200 ms é recusado e 300 ms é aceito',
    (tester) async {
      // Os dois lados da borda, em montagens separadas — dois toques longos na
      // mesma montagem cairiam um dentro da alça criada pelo outro.
      final rejected = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: threeMinutes,
          initialSplits: const [0.5],
          emissions: rejected,
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPressAt(_atSeconds(tester, threeMinutes, 0.2));
      await tester.pumpAndSettle();

      expect(
        rejected,
        isEmpty,
        reason: '200 ms está abaixo do piso; nada deveria ser emitido',
      );

      final accepted = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: threeMinutes,
          initialSplits: const [0.5],
          emissions: accepted,
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPressAt(_atSeconds(tester, threeMinutes, 0.3));
      await tester.pumpAndSettle();

      expect(
        accepted,
        hasLength(1),
        reason: '300 ms está acima do piso e deveria ser aceito',
      );
    },
  );

  testWidgets(
    'numa gravação curta demais para dois segmentos, arrastar não move a alça',
    (tester) async {
      // 250 ms não cabe duas vezes em 400 ms, então o piso passa de 0.5 e não
      // sobra posição legal nenhuma. O arraste tem de segurar a alça em vez de
      // estourar num clamp invertido.
      const tooShort = Duration(milliseconds: 400);
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: tooShort,
          initialSplits: const [0.5],
          emissions: emissions,
        ),
      );
      await tester.pumpAndSettle();

      final from = _atSeconds(tester, tooShort, 0.3);
      final to = _atSeconds(tester, tooShort, 0.05);
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(emissions, isEmpty);
    },
  );

  testWidgets(
    'com zoom suficiente, um corte a meio segundo de outro corte é aceito',
    (tester) async {
      // Numa gravação de 33 s a 400 dp e zoom 8, meio segundo vale ~48 px —
      // mais que o raio de toque da alça (36 px), então o toque longo cai fora
      // do marcador vizinho e exercita a cláusula de vizinhança de verdade.
      const zoom = 8.0;
      const pan = 0.4375;
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: thirtyThree,
          initialSplits: const [0.5],
          emissions: emissions,
          zoom: zoom,
          panFraction: pan,
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPressAt(
        _atSeconds(tester, thirtyThree, 17.0, zoom: zoom, panFraction: pan),
      );
      await tester.pumpAndSettle();

      expect(emissions, hasLength(1));
      final added = emissions.single.where((p) => p != 0.5).toList();
      expect(added, hasLength(1));
      expect(_seconds(added.single, thirtyThree), closeTo(17.0, 0.1));
    },
  );

  testWidgets(
    'toque longo a 100 ms da borda de um trecho excluído não cria corte',
    (tester) async {
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: const Duration(minutes: 1),
          initialSplits: const [],
          emissions: emissions,
          excludedRanges: const [
            ExcludedRange(startFraction: 0.3, endFraction: 0.5),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPressAt(
        _atSeconds(tester, const Duration(minutes: 1), 30.1),
      );
      await tester.pumpAndSettle();

      expect(emissions, isEmpty);
    },
  );

  testWidgets(
    'arrastar um corte contra a borda de um trecho excluído o segura a 250 ms',
    (tester) async {
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: const Duration(minutes: 1),
          initialSplits: const [1 / 3],
          emissions: emissions,
          excludedRanges: const [
            ExcludedRange(startFraction: 0.5, endFraction: 0.7),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final from = _atSeconds(tester, const Duration(minutes: 1), 20);
      final to = _atSeconds(tester, const Duration(minutes: 1), 30.1);
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();

      expect(
        _seconds(emissions.last.single, const Duration(minutes: 1)),
        closeTo(29.75, 0.01),
      );
    },
  );

  testWidgets(
    'um corte arrastado entre dois trechos próximos nunca termina a menos de '
    '250 ms de uma borda',
    (tester) async {
      const total = Duration(seconds: 10);
      const edges = [2.5, 3.0, 3.375, 3.5];
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: total,
          initialSplits: const [0.4],
          emissions: emissions,
          excludedRanges: const [
            ExcludedRange(startFraction: 0.3375, endFraction: 0.35),
            ExcludedRange(startFraction: 0.25, endFraction: 0.30),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final from = _atSeconds(tester, total, 4.0);
      final to = _atSeconds(tester, total, 3.05);
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();

      final mark = _seconds(emissions.last.single, total);
      expect(
        mark == 4.0 || edges.every((e) => (mark - e).abs() >= 0.25 - 1e-9),
        isTrue,
        reason: 'mark ended at $mark s',
      );
      final parts = keptPartsOf(
        splitPoints: emissions.last,
        excludedSegments: const {},
        excludedRanges: const [
          ExcludedRange(startFraction: 0.3375, endFraction: 0.35),
          ExcludedRange(startFraction: 0.25, endFraction: 0.30),
        ],
      );
      for (final p in parts) {
        expect(
          _seconds(p.endFraction - p.startFraction, total),
          greaterThanOrEqualTo(0.25 - 1e-9),
          reason: 'kept part ${p.startFraction}-${p.endFraction}',
        );
      }
    },
  );

  testWidgets(
    'um corte arrastado para uma folga de menos de 500 ms entre dois trechos '
    'fica onde estava',
    (tester) async {
      const total = Duration(seconds: 10);
      final emissions = <List<double>>[];
      await tester.pumpWidget(
        _harness(
          totalDuration: total,
          zoom: 4.0,
          panFraction: 0.2,
          initialSplits: const [0.3, 0.8],
          emissions: emissions,
          excludedRanges: const [
            ExcludedRange(startFraction: 0.2, endFraction: 0.3),
            ExcludedRange(startFraction: 0.34, endFraction: 0.4),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final from = _atSeconds(tester, total, 3.0, zoom: 4.0, panFraction: 0.2);
      final to = _atSeconds(tester, total, 3.2, zoom: 4.0, panFraction: 0.2);
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();

      final marks = emissions.isEmpty ? [0.3, 0.8] : emissions.last;
      expect(marks.map((m) => _seconds(m, total)), [
        closeTo(3.0, 0.01),
        closeTo(8.0, 0.01),
      ]);
    },
  );
}
