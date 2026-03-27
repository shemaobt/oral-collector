import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

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
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
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

    return SizedBox(
      width: 160,
      height: 210,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

          _buildMiniFab(
            offsetY: 130,
            icon: LucideIcons.mic,
            label: l10n.fab_normalRecord,
            color: colors.accent.withValues(alpha: 0.85),
            onTap: () {
              _close();
              widget.onNormalRecord();
            },
          ),

          _buildMiniFab(
            offsetY: 72,
            icon: LucideIcons.zap,
            label: l10n.fab_quickRecord,
            color: Colors.amber.shade700,
            onTap: () {
              _close();
              widget.onQuickRecord();
            },
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Semantics(
              label: 'Start recording',
              button: true,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _toggle,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.accent,
                          colors.accent.withValues(alpha: 0.85),
                        ],
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
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isOpen ? LucideIcons.x : LucideIcons.mic,
                        key: ValueKey(_isOpen),
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab({
    required double offsetY,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: ListenableBuilder(
        listenable: _expandAnimation,
        builder: (context, child) {
          final value = _expandAnimation.value;
          return Transform.translate(
            offset: Offset(0, -offsetY * value),
            child: Opacity(
              opacity: value,
              child: IgnorePointer(ignoring: value < 0.5, child: child),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 48,
                height: 48,
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
                child: Icon(icon, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
