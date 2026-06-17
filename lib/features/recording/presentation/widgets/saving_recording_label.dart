import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

/// "Saving recording…" label with three bouncing dots — shown below the timer
/// while finalization is in progress.
class SavingRecordingLabel extends StatefulWidget {
  const SavingRecordingLabel({super.key});

  @override
  State<SavingRecordingLabel> createState() => _SavingRecordingLabelState();
}

class _SavingRecordingLabelState extends State<SavingRecordingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DurationScale.ms1100,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BouncingDots(controller: _controller, color: colors.accent),
        const SizedBox(width: SpacingScale.s8),
        Text(
          AppLocalizations.of(context).recording_savingRecording,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SpacingScale.s24,
      height: SpacingScale.s16,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) _dot(controller.value, i * 0.18),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double t, double delay) {
    final phase = (t - delay) % 1.0;
    final lift = phase < 0.5 ? (phase * 2) : (1 - phase) * 2; // 0→1→0 triangle
    final size = 4.0;
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * lift),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
