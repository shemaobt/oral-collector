import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_durations.dart';

void main() {
  group('DurationScale', () {
    test('maps each named step to its millisecond duration', () {
      expect(DurationScale.ms120, const Duration(milliseconds: 120));
      expect(DurationScale.ms150, const Duration(milliseconds: 150));
      expect(DurationScale.ms200, const Duration(milliseconds: 200));
      expect(DurationScale.ms250, const Duration(milliseconds: 250));
      expect(DurationScale.ms300, const Duration(milliseconds: 300));
      expect(DurationScale.ms900, const Duration(milliseconds: 900));
      expect(DurationScale.ms1100, const Duration(milliseconds: 1100));
      expect(DurationScale.ms1200, const Duration(milliseconds: 1200));
    });
  });

  group('AppDurations', () {
    test('default extension exposes the scale values', () {
      const durations = AppDurations();
      expect(durations.ms120, DurationScale.ms120);
      expect(durations.ms200, DurationScale.ms200);
      expect(durations.ms1200, DurationScale.ms1200);
    });

    test('fallback equals a default-constructed instance', () {
      expect(AppDurations.fallback, const AppDurations());
      expect(AppDurations.fallback.hashCode, const AppDurations().hashCode);
    });

    test('copyWith overrides only the named field', () {
      const base = AppDurations();
      final modified = base.copyWith(ms200: const Duration(milliseconds: 500));
      expect(modified.ms200, const Duration(milliseconds: 500));
      expect(modified.ms300, base.ms300);
      expect(modified, isNot(base));
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const a = AppDurations();
      final b = a.copyWith(ms200: const Duration(milliseconds: 400));
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp interpolates at the midpoint', () {
      const a = AppDurations();
      final b = a.copyWith(ms200: const Duration(milliseconds: 400));
      expect(a.lerp(b, 0.5).ms200, const Duration(milliseconds: 300));
    });

    test('lerp with a non-AppDurations other returns itself', () {
      const a = AppDurations();
      expect(a.lerp(null, 0.5), a);
    });
  });
}
