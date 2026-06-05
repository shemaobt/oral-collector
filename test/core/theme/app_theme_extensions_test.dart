import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_durations.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

void main() {
  test('light theme registers all token extensions', () {
    final theme = AppTheme.lightTheme;
    expect(theme.extension<AppSpacing>(), isNotNull);
    expect(theme.extension<AppRadii>(), isNotNull);
    expect(theme.extension<AppDurations>(), isNotNull);
  });

  test('dark theme registers all token extensions', () {
    final theme = AppTheme.darkTheme;
    expect(theme.extension<AppSpacing>(), isNotNull);
    expect(theme.extension<AppRadii>(), isNotNull);
    expect(theme.extension<AppDurations>(), isNotNull);
  });
}
