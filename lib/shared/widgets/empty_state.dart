import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'app_disc.dart';

enum EmptyTone { calm, failed }

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.tone = EmptyTone.calm,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final EmptyTone tone;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(SpacingScale.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppDisc(
                    size: DiscSize.empty,
                    tone: tone == EmptyTone.failed
                        ? DiscTone.failed
                        : DiscTone.onCard,
                    child: Icon(icon),
                  ),
                  const SizedBox(height: _gap),
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: description == null ? 16 : 17,
                      fontWeight: description == null
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: _gap),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: colors.secondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: _gap),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
