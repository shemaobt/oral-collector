import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class EditVolumeControl extends StatelessWidget {
  const EditVolumeControl({
    super.key,
    required this.gainDb,
    required this.peakAmplitude,
    required this.onChanged,
    required this.volumeLabel,
    required this.clippingLabel,
    required this.boostOnSaveLabel,
    this.minDb = -12.0,
    this.maxDb = 12.0,
  });

  final double gainDb;
  final double peakAmplitude;
  final ValueChanged<double> onChanged;
  final String volumeLabel;
  final String clippingLabel;
  final String boostOnSaveLabel;
  final double minDb;
  final double maxDb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final peakDb = peakAmplitude > 0
        ? 20 * (math.log(peakAmplitude) / math.ln10)
        : -60.0;
    final peakAfterGain = (peakDb + gainDb).clamp(-60.0, 6.0);
    final fillFraction = ((peakAfterGain + 60) / 60).clamp(0.0, 1.0);

    Color meterColor;
    if (peakAfterGain >= -1) {
      meterColor = colors.error;
    } else if (peakAfterGain >= -3) {
      meterColor = const Color(0xFFE0A526);
    } else {
      meterColor = colors.success;
    }

    final gainLabel = gainDb == 0
        ? '0 dB'
        : '${gainDb > 0 ? '+' : ''}${gainDb.toStringAsFixed(1)} dB';
    final peakLabel = peakAfterGain > -60
        ? '${peakAfterGain.toStringAsFixed(1)} dB peak'
        : '—';
    final isClipping = peakAfterGain >= -1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                volumeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.foreground.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              if (gainDb > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    boostOnSaveLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colors.foreground.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              Text(
                gainLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: gainDb.clamp(minDb, maxDb),
              min: minDb,
              max: maxDb,
              divisions: ((maxDb - minDb) * 2).round(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fillFraction,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: meterColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                peakLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.5),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              if (isClipping)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    clippingLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
