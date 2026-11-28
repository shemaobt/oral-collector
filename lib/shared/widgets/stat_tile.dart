import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_tile.dart';
import 'brush_number.dart';

const double _radius = 18;
const double _minWidth = 108;
const double _numberHeight = 34;
final _digits = RegExp(r'[\d:]+');

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.hot = false,
  });

  final String value;
  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final small = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: colors.secondary,
    );
    final ink = hot ? colors.accent : colors.foreground;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _minWidth),
        child: AppTile(
          radius: _radius,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final run in _runs(value))
                    run.digits
                        ? BrushNumber(
                            run.text,
                            height: _numberHeight,
                            color: ink,
                          )
                        : Text(run.text, style: small),
                ],
              ),
              const SizedBox(height: SpacingScale.s8),
              Text(label, style: small),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Run = ({String text, bool digits});

List<_Run> _runs(String value) {
  final runs = <_Run>[];
  var at = 0;
  for (final m in _digits.allMatches(value)) {
    if (m.start > at) {
      runs.add((text: value.substring(at, m.start), digits: false));
    }
    runs.add((text: m.group(0)!, digits: true));
    at = m.end;
  }
  if (at < value.length) {
    runs.add((text: value.substring(at), digits: false));
  }
  return runs;
}
