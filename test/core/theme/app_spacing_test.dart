import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';

void main() {
  group('SpacingScale', () {
    test('maps each step to its 4px-grid value', () {
      expect(SpacingScale.s4, 4);
      expect(SpacingScale.s8, 8);
      expect(SpacingScale.s12, 12);
      expect(SpacingScale.s16, 16);
      expect(SpacingScale.s20, 20);
      expect(SpacingScale.s24, 24);
      expect(SpacingScale.s28, 28);
      expect(SpacingScale.s32, 32);
      expect(SpacingScale.s40, 40);
      expect(SpacingScale.s48, 48);
    });
  });

  group('AppSpacing', () {
    test('default extension exposes the scale values', () {
      const spacing = AppSpacing();
      expect(spacing.s4, SpacingScale.s4);
      expect(spacing.s16, SpacingScale.s16);
      expect(spacing.s48, SpacingScale.s48);
    });

    test('fallback equals a default-constructed instance', () {
      expect(AppSpacing.fallback, const AppSpacing());
      expect(AppSpacing.fallback.hashCode, const AppSpacing().hashCode);
    });

    test('copyWith overrides only the named field', () {
      const base = AppSpacing();
      final modified = base.copyWith(s16: 99);
      expect(modified.s16, 99);
      expect(modified.s8, base.s8);
      expect(modified, isNot(base));
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const a = AppSpacing();
      final b = a.copyWith(s16: 32);
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp interpolates linearly at the midpoint', () {
      const a = AppSpacing();
      final b = a.copyWith(s16: 32);
      expect(a.lerp(b, 0.5).s16, (a.s16 + b.s16) / 2);
    });

    test('lerp with a non-AppSpacing other returns itself', () {
      const a = AppSpacing();
      expect(a.lerp(null, 0.5), a);
    });
  });
}
