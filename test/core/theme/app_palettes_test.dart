import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/theme/app_palettes.dart';

void main() {
  // Value-lock tripwire (pixel-identical refactor, ENG-116): these literals
  // mirror the inline palettes previously in genre_card/project_card. On a
  // deliberate palette change, update both sides.
  const genre = <int>[
    0xFF3D8E80,
    0xFFC25010,
    0xFF5E7A2B,
    0xFF9B7040,
    0xFF4A7FA3,
    0xFFD06835,
    0xFF4E8A4A,
    0xFF8B5E9B,
  ];
  const project = <int>[
    0xFFD45200,
    0xFF1A8A78,
    0xFF477A12,
    0xFF8B5CF6,
    0xFFE0A526,
    0xFF2563EB,
  ];

  group('AppPalettes.genreAccent', () {
    test('maps each index to the expected accent', () {
      for (var i = 0; i < genre.length; i++) {
        expect(
          AppPalettes.genreAccent(i).toARGB32(),
          genre[i],
          reason: 'index $i',
        );
      }
    });

    test('wraps modulo the palette length', () {
      expect(AppPalettes.genreAccent(genre.length).toARGB32(), genre[0]);
      expect(AppPalettes.genreAccent(genre.length + 1).toARGB32(), genre[1]);
    });
  });

  group('AppPalettes.projectAccent', () {
    test('maps each index to the expected accent', () {
      for (var i = 0; i < project.length; i++) {
        expect(
          AppPalettes.projectAccent(i).toARGB32(),
          project[i],
          reason: 'index $i',
        );
      }
    });

    test('wraps modulo the palette length', () {
      expect(AppPalettes.projectAccent(project.length).toARGB32(), project[0]);
      expect(
        AppPalettes.projectAccent(project.length + 1).toARGB32(),
        project[1],
      );
    });
  });

  group('AppPalettes singletons', () {
    test('heroGenreAccent equals the first genre accent', () {
      expect(AppPalettes.heroGenreAccent.toARGB32(), 0xFF3D8E80);
      expect(
        AppPalettes.heroGenreAccent.toARGB32(),
        AppPalettes.genreAccent(0).toARGB32(),
      );
    });

    test('waveformCursorDefault equals the first project accent', () {
      expect(AppPalettes.waveformCursorDefault.toARGB32(), 0xFFD45200);
      expect(
        AppPalettes.waveformCursorDefault.toARGB32(),
        AppPalettes.projectAccent(0).toARGB32(),
      );
    });
  });
}
