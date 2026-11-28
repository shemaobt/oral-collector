import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../utils/format.dart';
import 'brush_number.dart';

class RecordingClock extends StatelessWidget {
  const RecordingClock({
    super.key,
    required this.elapsed,
    this.paused = false,
    this.height = 72,
  });

  final Duration elapsed;
  final bool paused;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BrushNumber(
      formatClock(elapsed),
      height: height,
      color: paused ? colors.secondary : colors.count,
      tabular: true,
    );
  }
}
