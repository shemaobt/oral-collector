import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_opacity.dart';

void main() {
  group('OpacityScale', () {
    test('maps each step to its alpha value', () {
      expect(OpacityScale.o06, 0.06);
      expect(OpacityScale.o08, 0.08);
      expect(OpacityScale.o10, 0.1);
      expect(OpacityScale.o12, 0.12);
      expect(OpacityScale.o15, 0.15);
      expect(OpacityScale.o30, 0.3);
      expect(OpacityScale.o40, 0.4);
      expect(OpacityScale.o50, 0.5);
      expect(OpacityScale.o55, 0.55);
      expect(OpacityScale.o60, 0.6);
      expect(OpacityScale.o70, 0.7);
    });
  });

  group('AppOpacity', () {
    test('default extension exposes the scale values', () {
      const opacity = AppOpacity();
      expect(opacity.o06, OpacityScale.o06);
      expect(opacity.o40, OpacityScale.o40);
      expect(opacity.o70, OpacityScale.o70);
    });

    test('copyWith overrides only the named field', () {
      const base = AppOpacity();
      final modified = base.copyWith(o40: 0.99);
      expect(modified.o40, 0.99);
      expect(modified.o06, base.o06);
      expect(modified, isNot(base));
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const a = AppOpacity();
      final b = a.copyWith(o40: 1);
      expect(a.lerp(b, 0), a);
      expect(a.lerp(b, 1), b);
    });

    test('lerp interpolates linearly at the midpoint', () {
      const a = AppOpacity();
      final b = a.copyWith(o40: 1);
      expect(a.lerp(b, 0.5).o40, (a.o40 + b.o40) / 2);
    });

    test('lerp with a non-AppOpacity other returns itself', () {
      const a = AppOpacity();
      expect(a.lerp(null, 0.5), a);
    });
  });
}
