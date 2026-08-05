import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_durations.dart';
import 'package:oral_collector/core/theme/app_opacity.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

void main() {
  test('light theme registers the expected token extensions', () {
    final theme = AppTheme.lightTheme;
    expect(theme.extension<AppSpacing>(), AppSpacing.fallback);
    expect(theme.extension<AppRadii>(), AppRadii.fallback);
    expect(theme.extension<AppDurations>(), AppDurations.fallback);
    expect(theme.extension<AppOpacity>(), AppOpacity.fallback);
  });

  test('dark theme registers the expected token extensions', () {
    final theme = AppTheme.darkTheme;
    expect(theme.extension<AppSpacing>(), AppSpacing.fallback);
    expect(theme.extension<AppRadii>(), AppRadii.fallback);
    expect(theme.extension<AppDurations>(), AppDurations.fallback);
    expect(theme.extension<AppOpacity>(), AppOpacity.fallback);
  });
}
