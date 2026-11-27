import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'hand_cut_rect.dart';

const double _padX = 18;
const double _radius = 22;
const double _buttonHeight = 44;

class NeedsYouBlock extends StatelessWidget {
  const NeedsYouBlock({
    super.key,
    required this.title,
    required this.text,
    required this.action,
  });

  final String title;
  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomPaint(
      painter: HandCutRectPainter(fill: colors.soft, radius: _radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _padX,
          vertical: SpacingScale.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineLarge!.copyWith(
                fontSize: 26,
                color: isDark ? colors.onSoft : colors.deep,
              ),
            ),
            const SizedBox(height: SpacingScale.s12),
            Text(
              text,
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.noteInk,
              ),
            ),
            const SizedBox(height: SpacingScale.s12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: _buttonHeight,
              ),
              child: action,
            ),
          ],
        ),
      ),
    );
  }
}
