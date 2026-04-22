import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class ImportDropZone extends StatefulWidget {
  const ImportDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.enabled = true,
    this.hoverLabel,
  });

  final Widget child;
  final ValueChanged<List<XFile>> onFilesDropped;
  final bool enabled;
  final String? hoverLabel;

  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  State<ImportDropZone> createState() => _ImportDropZoneState();
}

class _ImportDropZoneState extends State<ImportDropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    if (!ImportDropZone.isSupportedPlatform || !widget.enabled) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (_) {
        if (!_dragging) setState(() => _dragging = true);
      },
      onDragExited: (_) {
        if (_dragging) setState(() => _dragging = false);
      },
      onDragDone: (detail) {
        setState(() => _dragging = false);
        if (detail.files.isEmpty) return;
        widget.onFilesDropped(detail.files);
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: _DragOverlay(label: widget.hoverLabel),
              ),
            ),
        ],
      ),
    );
  }
}

class _DragOverlay extends StatelessWidget {
  const _DragOverlay({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colors.accent,
          radius: 16,
          strokeWidth: 2,
          dash: 8,
          gap: 6,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.upload, size: 48, color: colors.accent),
              if (label != null) ...[
                const SizedBox(height: 12),
                Text(
                  label!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final length = metric.length;
    var distance = 0.0;
    while (distance < length) {
      final next = (distance + dash).clamp(0, length).toDouble();
      final segment = metric.extractPath(distance, next);
      canvas.drawPath(segment, paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
