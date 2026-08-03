import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'complete_ficha_pill.dart';

/// Places the "complete details" pill over the recording detail screen (ENG-374).
///
/// It floats outside every scrollable so the prompt stays reachable however far
/// down the page the user has read, which also means it has to stay clear of
/// whatever else is parked at the bottom of the screen.
class CompleteFichaOverlay extends StatelessWidget {
  const CompleteFichaOverlay({
    super.key,
    required this.pendencyCount,
    required this.onTap,
  });

  /// The layout the detail screen switches to for tablets and desktops.
  static const double wideBreakpoint = 700;

  /// What the phone layout has to leave at the end of its scrollable so the
  /// floating pill does not cover the last card.
  static double scrollReserve(BuildContext context) =>
      SpacingScale.s48 * 2 + MediaQuery.paddingOf(context).bottom;

  /// The wide layout docks the player strip to the bottom edge: a fixed 72px
  /// control row inside SpacingScale.s12 of vertical padding and a hairline
  /// border, 97px in all. The pill has to sit above it — landing on it puts the
  /// pill's InkWell over the seek slider, and the audio stops being draggable.
  static const double _wideBottom = SpacingScale.s48 * 2 + SpacingScale.s16;

  final int pendencyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    return Positioned(
      left: 0,
      right: 0,
      // Measured from the top of the system gesture area, not from the physical
      // bottom of the screen: the Scaffold body runs under the home indicator.
      bottom:
          (isWide ? _wideBottom : SpacingScale.s28) +
          MediaQuery.paddingOf(context).bottom,
      child: Padding(
        // Positioned pins the Row's width, but a Row hands unbounded width to
        // its non-flexible children — so without this padding plus the
        // Flexible below, the pill lays itself out at infinite width and
        // spills its count badge past the right edge under a large font.
        padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: CompleteFichaPill(
                pendencyCount: pendencyCount,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
