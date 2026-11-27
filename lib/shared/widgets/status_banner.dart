import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';

const double _padX = 14;
const double _signGap = 10;

enum StatusBannerTone { calm, attention, failed }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.sign,
    required this.text,
    this.title,
    this.tone = StatusBannerTone.calm,
  });

  final Sign sign;
  final String text;
  final String? title;
  final StatusBannerTone tone;

  factory StatusBanner.offline(AppLocalizations l10n, {Key? key}) =>
      StatusBanner(
        key: key,
        sign: Sign.offline,
        text: l10n.status_offlineNotice,
      );

  factory StatusBanner.noProject(AppLocalizations l10n, {Key? key}) =>
      StatusBanner(
        key: key,
        sign: Sign.info,
        title: l10n.status_noProject,
        text: l10n.status_noProjectSubtitle,
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final (sheet, ink) = switch (tone) {
      StatusBannerTone.calm => (colors.pale, colors.foreground),
      StatusBannerTone.attention => (colors.wood, colors.foreground),
      StatusBannerTone.failed => (colors.soft, colors.onSoft),
    };

    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, height: 1.35, color: ink);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        0,
      ),
      child: CustomPaint(
        painter: HandCutRectPainter(fill: sheet, radius: RadiusScale.r16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _padX,
            vertical: SpacingScale.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrushSign(sign, size: 18, color: ink),
              const SizedBox(width: _signGap),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (title != null)
                        TextSpan(
                          text: '$title ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
