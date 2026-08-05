import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

/// A globe icon + language name + optional language-code chip. The name is
/// [Flexible] and ellipsizes so the row never overflows when it runs out of
/// width under large system fonts (ENG-180). Card and header call sites differ
/// only in spacing and chip styling.
class LanguageChipRow extends StatelessWidget {
  const LanguageChipRow.card({
    super.key,
    required this.languageName,
    required this.languageCode,
    required this.colors,
    required this.theme,
  }) : _iconSize = 13,
       _nameGap = 4,
       _chipGap = 6,
       _chipPadding = const EdgeInsets.symmetric(
         horizontal: SpacingScale.s8,
         vertical: 1,
       ),
       _chipRadius = 4,
       _accentChip = false;

  const LanguageChipRow.header({
    super.key,
    required this.languageName,
    required this.languageCode,
    required this.colors,
    required this.theme,
  }) : _iconSize = 14,
       _nameGap = 5,
       _chipGap = 8,
       _chipPadding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
       _chipRadius = 5,
       _accentChip = true;

  final String languageName;
  final String? languageCode;
  final AppColorSet colors;
  final ThemeData theme;

  final double _iconSize;
  final double _nameGap;
  final double _chipGap;
  final EdgeInsets _chipPadding;
  final double _chipRadius;
  final bool _accentChip;

  @override
  Widget build(BuildContext context) {
    final chipColor = _accentChip ? colors.accent : colors.secondary;
    return Row(
      children: [
        Icon(LucideIcons.globe, size: _iconSize, color: colors.secondary),
        SizedBox(width: _nameGap),
        Flexible(
          child: Text(
            languageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (languageCode != null) ...[
          SizedBox(width: _chipGap),
          Container(
            padding: _chipPadding,
            decoration: BoxDecoration(
              color: _accentChip
                  ? colors.accent.withValues(alpha: 0.15)
                  : colors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(_chipRadius),
            ),
            child: Text(
              languageCode!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontSize: 10,
                fontWeight: _accentChip ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
