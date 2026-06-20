import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class RecordFab extends StatelessWidget {
  const RecordFab({super.key, required this.onPressed, required this.colors});

  final VoidCallback onPressed;
  final AppColorSet colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).a11y_startRecording,
      button: true,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.accent, colors.accent.withValues(alpha: 0.85)],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.mic, size: 26, color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}
