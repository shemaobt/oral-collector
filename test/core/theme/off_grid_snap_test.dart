import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';

import '../../../tool/off_grid_snap_policy.dart';

// Pins the ENG-162 snap policy: the literal maps the codemod applies must equal
// the independently-computed nearest-token (with the 8pt tie-break), and every
// target must be a real token. This is the delta-verifier — a wrong direction or
// a non-token target fails here. (Completeness across lib/ is enforced separately
// by `dart run tool/snap_off_grid.dart --verify`.)
void main() {
  group('off-grid snap policy', () {
    test('token lists mirror the real SpacingScale / RadiusScale', () {
      expect(
        kSpacingTokens,
        [
          SpacingScale.s4,
          SpacingScale.s8,
          SpacingScale.s12,
          SpacingScale.s16,
          SpacingScale.s20,
          SpacingScale.s24,
          SpacingScale.s28,
          SpacingScale.s32,
          SpacingScale.s40,
          SpacingScale.s48,
        ].map((d) => d.toInt()).toList(),
      );

      expect(
        kRadiusTokens,
        [
          RadiusScale.r4,
          RadiusScale.r8,
          RadiusScale.r12,
          RadiusScale.r16,
          RadiusScale.r20,
          RadiusScale.r24,
          RadiusScale.r28,
          RadiusScale.r32,
        ].map((d) => d.toInt()).toList(),
      );
    });

    test('spacing map equals nearest token with the 8pt tie-break', () {
      for (final entry in kSpacingSnap.entries) {
        expect(
          entry.value,
          nearestToken(entry.key, kSpacingTokens),
          reason: 'spacing ${entry.key}',
        );
      }
    });

    test('radius map equals nearest token with the 8pt tie-break', () {
      for (final entry in kRadiusSnap.entries) {
        expect(
          entry.value,
          nearestToken(entry.key, kRadiusTokens),
          reason: 'radius ${entry.key}',
        );
      }
    });

    test('golden: exact signed-off literal->token mappings', () {
      expect(kSpacingSnap, {6: 8, 10: 8, 14: 16, 22: 24, 26: 24, 34: 32});
      expect(kRadiusSnap, {
        6: 8,
        10: 8,
        14: 16,
        22: 24,
        26: 24,
        34: 32,
        36: 32,
      });
    });
  });
}
