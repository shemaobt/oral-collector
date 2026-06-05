import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_radii.dart';

void main() {
  group('RadiusScale', () {
    test('maps each step to its 4px-grid value', () {
      expect(RadiusScale.r4, 4);
      expect(RadiusScale.r8, 8);
      expect(RadiusScale.r12, 12);
      expect(RadiusScale.r16, 16);
      expect(RadiusScale.r20, 20);
      expect(RadiusScale.r24, 24);
    });
  });

  group('AppRadii', () {
    test('default extension exposes the scale values', () {
      const radii = AppRadii();
      expect(radii.r4, RadiusScale.r4);
      expect(radii.r12, RadiusScale.r12);
      expect(radii.r24, RadiusScale.r24);
    });

    test('fallback equals a default-constructed instance', () {
      expect(AppRadii.fallback, const AppRadii());
      expect(AppRadii.fallback.hashCode, const AppRadii().hashCode);
    });

    test('copyWith overrides only the named field', () {
      const base = AppRadii();
      final modified = base.copyWith(r12: 99);
      expect(modified.r12, 99);
      expect(modified.r8, base.r8);
      expect(modified, isNot(base));
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const a = AppRadii();
      final b = a.copyWith(r12: 24);
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp interpolates linearly at the midpoint', () {
      const a = AppRadii();
      final b = a.copyWith(r12: 24);
      expect(a.lerp(b, 0.5).r12, (a.r12 + b.r12) / 2);
    });

    test('lerp with a non-AppRadii other returns itself', () {
      const a = AppRadii();
      expect(a.lerp(null, 0.5), a);
    });
  });
}
