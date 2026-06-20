import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class ExpandableRecordFab extends StatefulWidget {
  const ExpandableRecordFab({
    super.key,
    required this.onQuickRecord,
    required this.onNormalRecord,
    required this.colors,
  });

  final VoidCallback onQuickRecord;
  final VoidCallback onNormalRecord;
  final AppColorSet colors;

  @override
  State<ExpandableRecordFab> createState() => _ExpandableRecordFabState();
}

class _ExpandableRecordFabState extends State<ExpandableRecordFab>
    with SingleTickerProviderStateMixin {
  static const double _miniButtonSize = 48;
  static const double _mainButtonSize = 62;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DurationScale.ms200,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = widget.colors;

    // ENG-185: an intrinsic, bottom-anchored layout grows with the text scale
    // instead of clipping inside a fixed-size corner box. The mini-fabs stay in
    // the tree (so their positions are laid out, not hardcoded) and only fade /
    // slide in, which keeps the layout footprint stable during the animation.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildMiniFab(
          icon: LucideIcons.mic,
          label: l10n.fab_normalRecord,
          color: colors.accent.withValues(alpha: 0.85),
          onTap: () {
            _close();
            widget.onNormalRecord();
          },
        ),
        const SizedBox(height: SpacingScale.s12),
        _buildMiniFab(
          icon: LucideIcons.zap,
          label: l10n.fab_quickRecord,
          color: colors.warning,
          onTap: () {
            _close();
            widget.onQuickRecord();
          },
        ),
        const SizedBox(height: SpacingScale.s12),
        _buildMainFab(l10n, colors),
      ],
    );
  }

  Widget _buildMainFab(AppLocalizations l10n, AppColorSet colors) {
    return Semantics(
      label: l10n.a11y_startRecording,
      button: true,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _toggle,
          customBorder: const CircleBorder(),
          child: Container(
            width: _mainButtonSize,
            height: _mainButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.accent, colors.accent.withValues(alpha: 0.85)],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: DurationScale.ms200,
              child: Icon(
                _isOpen ? LucideIcons.x : LucideIcons.mic,
                key: ValueKey(_isOpen),
                size: 26,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // ENG-185: cap the label so long locales wrap instead of pushing the cluster
    // off-screen. It wraps (never ellipsizes), so the label stays fully legible.
    final maxLabelWidth =
        MediaQuery.sizeOf(context).width -
        (_miniButtonSize + SpacingScale.s8 + SpacingScale.s16 * 2);

    return FadeTransition(
      opacity: _expandAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IgnorePointer(
          ignoring: !_isOpen,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s8,
                    vertical: SpacingScale.s8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusScale.r8),
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SpacingScale.s8),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: _miniButtonSize,
                  height: _miniButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
