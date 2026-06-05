import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_durations.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/core/theme/context_tokens.dart';

void main() {
  testWidgets('context tokens resolve through the app light theme', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ctx.spacing.s16, 16);
    expect(ctx.radii.r12, 12);
    expect(ctx.durations.ms200, const Duration(milliseconds: 200));
  });

  testWidgets('context tokens resolve through the app dark theme', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ctx.spacing.s24, 24);
    expect(ctx.radii.r16, 16);
    expect(ctx.durations.ms200, const Duration(milliseconds: 200));
  });

  testWidgets('context tokens fall back to the scale without a registered '
      'extension', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ctx.spacing.s16, SpacingScale.s16);
    expect(ctx.radii.r12, RadiusScale.r12);
    expect(ctx.durations.ms200, DurationScale.ms200);
  });
}
