import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/trim_waveform_panel.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

typedef ZoomPan = ({double zoom, double panFraction});

class _ScrubCapture {
  final List<double> playheadCalls = [];
  final List<ZoomPan> zoomPanCalls = [];
}

Widget _harness({
  required double zoom,
  required double panFraction,
  required _ScrubCapture capture,
  double width = 400,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: TrimWaveformPanel(
            waveformBars: List<double>.filled(200, 0.5),
            splitPoints: const [],
            onSplitPointsChanged: (_) {},
            playingSegment: null,
            excludedSegments: const {},
            hasSplits: false,
            keptCount: 1,
            segmentCount: 1,
            totalDurationLabel: '00:00.00',
            totalDurationShortLabel: '0s',
            onClearAll: () {},
            zoom: zoom,
            panFraction: panFraction,
            playheadFraction: 0.1,
            onPlayheadSeek: capture.playheadCalls.add,
            onZoomPanChanged: capture.zoomPanCalls.add,
            onResetZoom: () {},
          ),
        ),
      ),
    ),
  );
}

Rect _minimapRect(WidgetTester tester) {
  final finder = find.byKey(kTrimMinimapKey);
  expect(finder, findsOneWidget);
  final box = tester.renderObject<RenderBox>(finder);
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

Offset _atFraction(Rect r, double fraction) {
  return Offset(r.left + r.width * fraction, r.center.dy);
}

void main() {
  testWidgets('tap no minimap centraliza viewport e move playhead', (
    tester,
  ) async {
    final capture = _ScrubCapture();
    await tester.pumpWidget(
      _harness(zoom: 4.0, panFraction: 0.0, capture: capture),
    );
    await tester.pumpAndSettle();

    final rect = _minimapRect(tester);
    await tester.tapAt(_atFraction(rect, 0.5));
    await tester.pumpAndSettle();

    expect(capture.playheadCalls, isNotEmpty);
    expect(capture.playheadCalls.last, closeTo(0.5, 0.02));

    expect(capture.zoomPanCalls, isNotEmpty);
    final last = capture.zoomPanCalls.last;
    expect(last.zoom, 4.0);
    // viewportSize = 1/4 = 0.25; centered = 0.5 - 0.125 = 0.375
    expect(last.panFraction, closeTo(0.375, 0.02));
  });

  testWidgets(
    'tap proximo borda direita clampa pan para 1 - 1/zoom e playhead ~ 1.0',
    (tester) async {
      final capture = _ScrubCapture();
      await tester.pumpWidget(
        _harness(zoom: 4.0, panFraction: 0.0, capture: capture),
      );
      await tester.pumpAndSettle();

      final rect = _minimapRect(tester);
      // Bem perto da borda direita.
      await tester.tapAt(_atFraction(rect, 0.99));
      await tester.pumpAndSettle();

      expect(capture.playheadCalls, isNotEmpty);
      expect(capture.playheadCalls.last, closeTo(1.0, 0.02));

      expect(capture.zoomPanCalls, isNotEmpty);
      final last = capture.zoomPanCalls.last;
      expect(last.zoom, 4.0);
      // maxPan = 1 - 1/4 = 0.75
      expect(last.panFraction, closeTo(0.75, 0.001));
    },
  );

  testWidgets('tap proximo borda esquerda clampa pan para 0 e playhead ~ 0.0', (
    tester,
  ) async {
    final capture = _ScrubCapture();
    await tester.pumpWidget(
      _harness(zoom: 4.0, panFraction: 0.6, capture: capture),
    );
    await tester.pumpAndSettle();

    final rect = _minimapRect(tester);
    await tester.tapAt(_atFraction(rect, 0.01));
    await tester.pumpAndSettle();

    expect(capture.playheadCalls, isNotEmpty);
    expect(capture.playheadCalls.last, closeTo(0.0, 0.02));

    expect(capture.zoomPanCalls, isNotEmpty);
    final last = capture.zoomPanCalls.last;
    expect(last.zoom, 4.0);
    expect(last.panFraction, closeTo(0.0, 0.001));
  });

  testWidgets('drag no minimap emite seeks contínuos crescentes', (
    tester,
  ) async {
    final capture = _ScrubCapture();
    await tester.pumpWidget(
      _harness(zoom: 4.0, panFraction: 0.0, capture: capture),
    );
    await tester.pumpAndSettle();

    final rect = _minimapRect(tester);
    final start = _atFraction(rect, 0.2);
    final mid = _atFraction(rect, 0.55);
    final end = _atFraction(rect, 0.9);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(mid);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      capture.playheadCalls.length,
      greaterThanOrEqualTo(3),
      reason: 'esperava pelo menos 3 seeks (start + 2 moves)',
    );
    // Sequência deve ser não-decrescente já que arrastamos da esquerda → direita.
    for (var i = 1; i < capture.playheadCalls.length; i++) {
      expect(
        capture.playheadCalls[i],
        greaterThanOrEqualTo(capture.playheadCalls[i - 1] - 0.001),
      );
    }
    expect(capture.playheadCalls.last, closeTo(0.9, 0.03));

    final lastPan = capture.zoomPanCalls.last;
    // viewport centralizado em 0.9: newPan = 0.9 - 0.125 = 0.775 → clamp 0.75
    expect(lastPan.zoom, 4.0);
    expect(lastPan.panFraction, closeTo(0.75, 0.02));
  });

  testWidgets('zoom permanece inalterado durante scrub', (tester) async {
    final capture = _ScrubCapture();
    await tester.pumpWidget(
      _harness(zoom: 4.0, panFraction: 0.0, capture: capture),
    );
    await tester.pumpAndSettle();

    final rect = _minimapRect(tester);
    await tester.tapAt(_atFraction(rect, 0.3));
    await tester.pumpAndSettle();
    await tester.tapAt(_atFraction(rect, 0.7));
    await tester.pumpAndSettle();

    expect(capture.zoomPanCalls, isNotEmpty);
    for (final call in capture.zoomPanCalls) {
      expect(call.zoom, 4.0);
    }
  });

  testWidgets('minimap não aparece quando zoom = 1.0', (tester) async {
    final capture = _ScrubCapture();
    await tester.pumpWidget(
      _harness(zoom: 1.0, panFraction: 0.0, capture: capture),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kTrimMinimapKey), findsNothing);
  });
}
