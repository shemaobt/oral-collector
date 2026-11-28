import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'brush_number.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';
import 'pressable.dart';

const double _radius = 22;
const double _rowHeight = 56;
const double _countSlot = 32;
const double _countHeight = 30;
const double _chevron = 14;
const double _gap = 14;

class SlabRow {
  const SlabRow({
    required this.count,
    required this.label,
    required this.action,
    this.onTap,
  });

  final int count;
  final String label;
  final String action;
  final VoidCallback? onTap;
}

class SlabCard extends StatelessWidget {
  const SlabCard({super.key, required this.title, required this.rows});

  final String title;
  final List<SlabRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = colors.onPrimary;
    final actionColor = dark ? colors.pale : colors.sand;
    final line = ink.withValues(alpha: dark ? 0.22 : 0.16);
    final widest = rows
        .map((r) => '${r.count}')
        .fold<String>('', (w, c) => c.length > w.length ? c : w);
    return CustomPaint(
      painter: HandCutRectPainter(
        fill: dark ? colors.sand : colors.primary,
        radius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge!.copyWith(fontSize: 26, color: ink),
                ),
              ),
              for (var i = 0; i < rows.length; i++)
                _Row(
                  row: rows[i],
                  widest: widest,
                  ink: ink,
                  actionColor: actionColor,
                  line: i == rows.length - 1 ? null : line,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.widest,
    required this.ink,
    required this.actionColor,
    required this.line,
  });

  final SlabRow row;
  final String widest;
  final Color ink;
  final Color actionColor;
  final Color? line;

  @override
  Widget build(BuildContext context) {
    final word = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w500);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: line == null ? null : Border(bottom: BorderSide(color: line!)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.textScalerOf(context).scale(_countSlot),
                ),
                child: Stack(
                  children: [
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: BrushNumber(
                        widest,
                        height: _countHeight,
                        tabular: true,
                      ),
                    ),
                    BrushNumber(
                      '${row.count}',
                      height: _countHeight,
                      color: ink,
                      tabular: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Text(row.label, style: word.copyWith(color: ink)),
              ),
              const SizedBox(width: _gap),
              Text(row.action, style: word.copyWith(color: actionColor)),
              const SizedBox(width: 4),
              BrushSign(Sign.next, size: _chevron, color: actionColor),
            ],
          ),
        ),
      ),
    );
    return row.onTap == null
        ? content
        : Pressable(onTap: row.onTap, child: content);
  }
}
