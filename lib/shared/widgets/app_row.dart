import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppRowKind {
  recording(minHeight: 66, leadWidth: 44, padTop: 11, padBottom: 11),
  setting(minHeight: 58, leadWidth: 28, padTop: 9, padBottom: 9),
  compact(minHeight: 54, leadWidth: 28, padTop: 8, padBottom: 8);

  const AppRowKind({
    required this.minHeight,
    required this.leadWidth,
    required this.padTop,
    required this.padBottom,
  });

  final double minHeight;
  final double leadWidth;
  final double padTop;
  final double padBottom;
}

const double _gap = 14;
const double _belowPadBottom = 12;
const double _padBottomWithBelow = 8;

class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.kind = AppRowKind.recording,
    this.lead,
    this.detail,
    this.state,
    this.below,
    this.destructive = false,
  });

  final String title;
  final AppRowKind kind;
  final Widget? lead;
  final String? detail;
  final Widget? state;
  final Widget? below;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final ink = destructive ? colors.error : colors.foreground;
    final row = Row(
      children: [
        if (lead != null) ...[
          SizedBox(
            width: kind.leadWidth,
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: lead!,
            ),
          ),
          const SizedBox(width: _gap),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  color: ink,
                  fontSize: 17,
                  height: 1.25,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: colors.secondary),
                ),
            ],
          ),
        ),
        if (state != null) ...[const SizedBox(width: _gap), state!],
      ],
    );
    final hasBelow = below != null;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: kind.padTop,
        bottom: hasBelow ? _belowPadBottom : kind.padBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  kind.minHeight -
                  kind.padTop -
                  (hasBelow ? _padBottomWithBelow : kind.padBottom),
            ),
            child: row,
          ),
          if (hasBelow) ...[
            const SizedBox(height: _padBottomWithBelow),
            Padding(
              padding: EdgeInsetsDirectional.only(start: kind.leadWidth + _gap),
              child: below,
            ),
          ],
        ],
      ),
    );
  }
}
