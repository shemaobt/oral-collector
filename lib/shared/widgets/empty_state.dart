import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import 'app_disc.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

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
                    child: Icon(icon, size: 30, color: colors.secondary),
                  ),
                  const SizedBox(height: SpacingScale.s20),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: SpacingScale.s8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingScale.s16,
                      ),
                      child: Text(
                        description!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.secondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: SpacingScale.s24),
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
