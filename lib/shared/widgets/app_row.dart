import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppRowKind {
  recording(height: 44, leadWidth: 44, pad: 11),
  setting(height: 40, leadWidth: 28, pad: 9),
  compact(height: 38, leadWidth: 28, pad: 8);

  const AppRowKind({
    required this.height,
    required this.leadWidth,
    required this.pad,
  });

  final double height;
  final double leadWidth;
  final double pad;
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
    final row = LayoutBuilder(
      builder: (context, box) => Row(
        spacing: _gap,
        children: [
          if (lead != null)
            SizedBox(
              width: kind.leadWidth,
              child: IconTheme.merge(
                data: IconThemeData(color: ink),
                child: lead!,
              ),
            ),
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
          if (state != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.4),
              child: state,
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: kind.pad,
        bottom: below != null ? _belowPadBottom : kind.pad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: kind.height),
            child: row,
          ),
          if (below != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: kind.leadWidth + _gap,
                top: _padBottomWithBelow,
              ),
              child: below,
            ),
        ],
      ),
    );
  }
}
