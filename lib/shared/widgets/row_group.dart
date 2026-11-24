import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_tile.dart';

class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children});

  static const double _rowMinHeight = 56;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wash = AppColors.of(context).wash;
    return AppTile(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s16,
        vertical: SpacingScale.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: wash),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: children[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
