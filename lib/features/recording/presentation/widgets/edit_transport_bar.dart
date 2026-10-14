import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';

class EditTransportBar extends StatelessWidget {
  const EditTransportBar({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s12,
        vertical: SpacingScale.s8,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RadiusScale.r12),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPlayPause();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(RadiusScale.r8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: SpacingScale.s12),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(text: formatPositionCentis(position)),
                    TextSpan(
                      text: ' / ${formatPositionCentis(duration)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
