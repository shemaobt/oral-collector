import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 26, height: 1),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
