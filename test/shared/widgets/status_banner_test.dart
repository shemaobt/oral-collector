import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/status_banner.dart';

void main() {
  for (final dark in [false, true]) {
    final colors = dark ? AppColors.dark : AppColors.light;
    final tones = {
      StatusBannerVariant.plain: (colors.surfaceAlt, colors.foreground),
      StatusBannerVariant.warn: (colors.woodSoft, colors.woodText),
      StatusBannerVariant.error: (colors.brickSoft, colors.error),
      StatusBannerVariant.hot: (colors.soft, colors.deep),
      StatusBannerVariant.info: (colors.bridgeSoft, colors.infoText),
    };
    for (final entry in tones.entries) {
      testWidgets('${entry.key.name} in ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Scaffold(
              body: StatusBanner(
                icon: LucideIcons.info,
                title: 'Title',
                subtitle: 'Subtitle',
                variant: entry.key,
              ),
            ),
          ),
        );
        final box =
            tester
                    .widget<Container>(
                      find.descendant(
                        of: find.byType(StatusBanner),
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration!
                as BoxDecoration;
        final (background, foreground) = entry.value;
        expect(box.color, background);
        expect(tester.widget<Icon>(find.byType(Icon)).color, foreground);
        expect(
          tester.widget<Text>(find.text('Title')).style?.color,
          foreground,
        );
        expect(
          tester.widget<Text>(find.text('Subtitle')).style?.color,
          foreground,
        );
      });
    }
  }
}
