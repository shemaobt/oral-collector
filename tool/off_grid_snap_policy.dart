// Off-grid -> token snap policy for ENG-162 (see docs/adr/ADR-0002-design-tokens.md).
//
// Rule: snap each off-grid literal to the nearest token value. On an exact tie
// between two adjacent tokens, break toward the multiple of 8 (round-half-to-even
// on the 4px grid, matching IEEE-754's default and the M3 8pt grid line). Radii
// snap within the (extended) radius token scale.
//
// Pure data + arithmetic, no imports: shared by the codemod (tool/snap_off_grid.dart)
// and the policy test (test/core/theme/off_grid_snap_test.dart) so there is one
// source of truth, while the test re-derives the maps from [nearestToken] to catch
// a wrong entry.

/// Curated spacing token scale (`SpacingScale.sN`).
const List<int> kSpacingTokens = [4, 8, 12, 16, 20, 24, 28, 32, 40, 48];

/// Curated radius token scale (`RadiusScale.rN`) — extended with 28/32 in ENG-162.
const List<int> kRadiusTokens = [4, 8, 12, 16, 20, 24, 28, 32];

/// The off-grid literals this migration normalizes.
const Set<int> kOffGridValues = {6, 10, 14, 22, 26, 34, 36};

/// Authoritative literal -> token-value map for spacing contexts.
const Map<int, int> kSpacingSnap = {
  6: 8,
  10: 8,
  14: 16,
  22: 24,
  26: 24,
  34: 32,
};

/// Authoritative literal -> token-value map for radius contexts.
const Map<int, int> kRadiusSnap = {
  6: 8,
  10: 8,
  14: 16,
  22: 24,
  26: 24,
  34: 32,
  36: 32,
};

/// Nearest token to [value]; on an exact tie, the multiple of 8 wins
/// (round-half-to-even on the 4px grid). Independent restatement of the policy
/// used by the test to verify [kSpacingSnap] / [kRadiusSnap].
int nearestToken(int value, List<int> tokens) {
  var best = tokens.first;
  var bestDist = (value - best).abs();
  for (final t in tokens.skip(1)) {
    final d = (value - t).abs();
    if (d < bestDist) {
      best = t;
      bestDist = d;
    } else if (d == bestDist && t % 8 == 0 && best % 8 != 0) {
      best = t; // tie -> prefer the stronger (8pt) grid line
    }
  }
  return best;
}
