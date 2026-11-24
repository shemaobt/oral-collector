import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/genre_colors.dart';

void main() {
  int disc(GenreColors set, int index) =>
      set.forGenre(index, 'narrative')!.disc.toARGB32();
  int soft(GenreColors set, int index) =>
      set.forGenre(index, 'narrative')!.soft.toARGB32();

  test('light: positions 0-3 take g1-g4 and position 4 takes g1 again', () {
    expect(
      [for (var i = 0; i < 5; i++) disc(GenreColors.light, i)],
      [0xFFC9A26B, 0xFF89AAA3, 0xFF777D45, 0xFF9C5D45, 0xFFC9A26B],
    );
  });

  test('dark: g3 and g4 are lifted, g1 and g2 stay', () {
    expect(
      [for (var i = 0; i < 4; i++) disc(GenreColors.dark, i)],
      [0xFFC9A26B, 0xFF89AAA3, 0xFF9EA562, 0xFFC77D60],
    );
  });

  test('tinted card backgrounds follow the mode', () {
    expect(
      [for (var i = 0; i < 4; i++) soft(GenreColors.light, i)],
      [0xFFF6EAD3, 0xFFE1ECE8, 0xFFECEDD8, 0xFFF2E2DA],
    );
    expect(
      [for (var i = 0; i < 4; i++) soft(GenreColors.dark, i)],
      [0xFF2A2318, 0xFF1B2624, 0xFF232518, 0xFF2E1E17],
    );
  });

  test('the unclassified genre has no colour at any position', () {
    for (final set in [GenreColors.light, GenreColors.dark]) {
      for (var i = 0; i < 6; i++) {
        expect(set.forGenre(i, 'unclassified'), isNull, reason: 'index $i');
      }
    }
  });
}
