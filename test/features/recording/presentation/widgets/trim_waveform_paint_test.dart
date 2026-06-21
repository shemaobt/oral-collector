// Characterization of _SplitWaveformPainter.paint draw output (ENG-210).
//
// The painter is private, so we pump TrimWaveformPanel (which hosts it),
// pull the painter out of its CustomPaint, and replay paint() onto a canvas
// that records every draw call. The per-method call counts pin the painting
// behaviour so the cyclomatic-complexity refactor (extracting sub-draws) is
// provably behaviour-preserving — the counts must stay identical.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/trim_waveform_panel.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _RecordingCanvas implements Canvas {
  final List<String> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    return null;
  }
}

Widget _harness({double width = 400}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: TrimWaveformPanel(
            waveformBars: List<double>.filled(12, 0.5),
            splitPoints: const [0.33, 0.66],
            onSplitPointsChanged: (_) {},
            playingSegment: 0,
            excludedSegments: const {1},
            hasSplits: true,
            keptCount: 2,
            segmentCount: 3,
            totalDurationLabel: '00:00.00',
            totalDurationShortLabel: '0s',
            onClearAll: () {},
            zoom: 1.0,
            panFraction: 0.0,
            playheadFraction: 0.5,
            onPlayheadSeek: (_) {},
            onZoomPanChanged: (_) {},
            onResetZoom: () {},
          ),
        ),
      ),
    ),
  );
}

CustomPaint _splitPaint(WidgetTester tester) {
  final all = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
  return all.firstWhere(
    (cp) => cp.painter?.runtimeType.toString() == '_SplitWaveformPainter',
  );
}

Map<String, int> _countCalls(WidgetTester tester) {
  final cp = _splitPaint(tester);
  final size = tester.getSize(find.byWidget(cp));
  final rec = _RecordingCanvas();
  cp.painter!.paint(rec, size);
  final counts = <String, int>{};
  for (final c in rec.calls) {
    counts[c] = (counts[c] ?? 0) + 1;
  }
  return counts;
}

void main() {
  testWidgets('paint emits a stable set of draw calls', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final counts = _countCalls(tester);

    // Load-bearing for this refactor: the tint loop that moved into
    // _drawSegmentTints emits one background fill + one tint rect per segment
    // (3 segments) = 4 drawRect. This count must stay exact.
    expect(counts['Symbol("drawRect")'], 4);

    // Stable structural counts (driven by segment/marker/bar counts, not by
    // pixel geometry): 12 bars, 3 segment labels, 2 split-marker handle dots +
    // 2 playhead dots, and the single clipped save/restore frame.
    expect(counts['Symbol("drawRRect")'], 12);
    expect(counts['Symbol("drawParagraph")'], 3);
    expect(counts['Symbol("drawCircle")'], 4);
    expect(counts['Symbol("save")'], 2);
    expect(counts['Symbol("restore")'], 2);
    expect(counts['Symbol("clipRRect")'], 1);
    expect(counts['Symbol("clipRect")'], 1);

    // Hatch + dashed split markers + playhead emit many lines; the exact total
    // is dash/handle geometry that this refactor does not touch, so assert that
    // they draw rather than pinning a rounding-sensitive absolute.
    expect(counts['Symbol("drawLine")'], greaterThan(0));
  });
}
