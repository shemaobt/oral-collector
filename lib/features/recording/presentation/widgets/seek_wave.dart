import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/waveform_visualizer.dart';

const _kitHeights = <int>[
  39, 28, 69, 23, 61, 47, 22, 55, 18, 44, 18, 18, 34, 51, 15, 19, //
  35, 48, 33, 27, 56, 13, 60, 31, 23, 23, 39, 80, 32, 65, 70, 47, //
  60, 21, 19, 28, 55, 36, 27, 38, 30, 22, 42, 38, 19, 36, 36, 58, //
  55, 31, 81, 24, 48, 77, 30, 58, 21, 70, 76, 58, 75, 34, 54, 44,
];

const _waveHeight = 28.0;
const _barWidth = 4.0;
const _barGap = 3.0;
const _barMinHeight = 2.0;

final _kitAmplitudes = [
  for (final h in _kitHeights)
    (h / 100 * _waveHeight - _barMinHeight) / (_waveHeight - _barMinHeight),
];

class SeekWave extends StatelessWidget {
  const SeekWave({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  double get _fraction => duration == Duration.zero
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  void _seekTo(double fraction) {
    if (duration == Duration.zero) return;
    final ms = (fraction.clamp(0.0, 1.0) * duration.inMilliseconds).round();
    onSeek(Duration(milliseconds: ms));
  }

  KeyEventResult _onKey(KeyEvent event, double step, bool rtl) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final forward =
        key == LogicalKeyboardKey.arrowUp ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight);
    final backward =
        key == LogicalKeyboardKey.arrowDown ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft);
    if (!forward && !backward) return KeyEventResult.ignored;
    _seekTo(_fraction + (forward ? step : -step));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final step =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? 0.1
        : 0.05;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final enabled = duration != Duration.zero;
    String percent(double f) => '${(f.clamp(0.0, 1.0) * 100).round()}%';

    return Semantics(
      slider: true,
      value: percent(_fraction),
      increasedValue: percent(_fraction + step),
      decreasedValue: percent(_fraction - step),
      onIncrease: enabled ? () => _seekTo(_fraction + step) : null,
      onDecrease: enabled ? () => _seekTo(_fraction - step) : null,
      excludeSemantics: true,
      child: Focus(
        onKeyEvent: (_, event) => _onKey(event, step, rtl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : _waveHeight;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final fromStart = details.localPosition.dx / width;
                _seekTo(rtl ? 1 - fromStart : fromStart);
              },
              child: SizedBox(
                height: height,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ClipRect(
                    child: SizedBox(
                      width: width,
                      child: WaveformVisualizer(
                        amplitudes: [
                          for (
                            var i = 0;
                            i < width / (_barWidth + _barGap);
                            i++
                          )
                            _kitAmplitudes[i % _kitAmplitudes.length],
                        ],
                        barWidth: _barWidth,
                        barSpacing: _barGap,
                        height: _waveHeight,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
