// ENG-354: the Dart half of a shared test vector. The other half is
// `tests/test_recording_description_rule.py` in the tripod-api repository,
// against `app/utils/description_rule.py`. Both halves run the same character
// sequences and assert the same verdicts, so a divergence between the two
// implementations of the rule shows up as a failing test on one side rather
// than as a recording the app accepts and the API then refuses.
//
// Keep the cases below character-for-character identical to the Python file.
import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/utils/recording_description.dart';

/// The five cases where a naive implementation diverges: matras and diacritics
/// attach to their base, a ZWJ sequence is one cluster however many people are
/// in it, and jamo L+V compose into one syllable.
/// Each entry is twenty clusters.
final _sharedVector = <String, String>{
  'cjk': '時間' * 10, // U+6642 U+9593
  'devanagari_with_matras': 'कि' * 20, // U+0915 + U+093F (vowel sign)
  'arabic_with_diacritics': 'بَ' * 20, // U+0628 + U+064E (fatha)
  'emoji_zwj_family': '\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}' * 20,
  // U+1100 + U+1161 as separate jamo, not the precomposed U+AC00: written as
  // escapes because editors and filesystems compose the literal form away.
  'hangul_jamo': '\u{1100}\u{1161}' * 20,
};

void main() {
  group('shared description vector (mirrors tests/test_recording_description_'
      'rule.py in tripod-api)', () {
    test('the threshold counts graphemes, not code points or code units', () {
      // A flag is two code points, four UTF-16 units, and one thing a person
      // typed. This is the case that dies if anyone swaps in `String.length`.
      final flags = '\u{1F1E7}\u{1F1F7}' * 20;

      expect(flags.length, greaterThan(minDescriptionGraphemes));
      expect(flags.characters.length, 20);
      expect(isDescriptionSufficient(flags), isTrue);
    });

    test('the threshold is twenty clusters', () {
      expect(isDescriptionSufficient('a' * 19), isFalse);
      expect(isDescriptionSufficient('a' * 20), isTrue);
    });

    test('an absent or blank description is insufficient', () {
      expect(isDescriptionSufficient(null), isFalse);
      expect(isDescriptionSufficient(''), isFalse);
      expect(isDescriptionSufficient(' ' * 40), isFalse);
    });

    test('counting is invariant under NFC', () {
      // The client does not normalise before counting, on the argument that
      // composition never merges across cluster boundaries. The API normalises
      // anyway, so the two only agree while that holds.
      final decomposed = 'e\u{301}' * 20;
      final composed = '\u{E9}' * 20;

      expect(decomposed.characters.length, 20);
      expect(composed.characters.length, 20);
      expect(isDescriptionSufficient(decomposed), isTrue);
      expect(isDescriptionSufficient(composed), isTrue);
    });

    test('a combining mark does not buy a cluster', () {
      // Nineteen letters plus nineteen combining acutes is still nineteen
      // clusters. A code-point or UTF-16 count would let it through.
      final text = 'a\u{301}' * 19;

      expect(text.length, greaterThan(minDescriptionGraphemes));
      expect(text.characters.length, 19);
      expect(isDescriptionSufficient(text), isFalse);
    });

    test('U+FEFF is trimmed at both ends', () {
      expect(isDescriptionSufficient('\u{FEFF}${'a' * 20}\u{FEFF}'), isTrue);
      expect(isDescriptionSufficient('\u{FEFF}${'a' * 19}\u{FEFF}'), isFalse);
    });

    test('U+001C-U+001F are not trimmed and count as clusters', () {
      // The API hand-wrote its trim set to exclude these because `str.strip()`
      // does strip them: inheriting the stdlib default there would make the
      // API refuse text the client already accepted. Nineteen letters between
      // two separators is twenty-one clusters on both sides.
      expect(isDescriptionSufficient('\u{1C}${'a' * 19}\u{1F}'), isTrue);
      expect(isDescriptionSufficient('\u{1C}${'a' * 20}\u{1F}'), isTrue);
      expect(('\u{1C}${'a' * 19}\u{1F}').characters.length, 21);
    });

    test('ordinary whitespace is trimmed at both ends', () {
      expect(isDescriptionSufficient('  ${'a' * 19}\n\t'), isFalse);
      expect(isDescriptionSufficient('  ${'a' * 20}\n\t'), isTrue);
    });

    test('interior whitespace counts', () {
      // Ten words of two letters is twenty clusters of text and nineteen
      // spaces between them.
      expect(isDescriptionSufficient(List.filled(10, 'ab').join(' ')), isTrue);
    });

    for (final entry in _sharedVector.entries) {
      test('${entry.key} counts the same on both sides', () {
        final text = entry.value;

        expect(text.characters.length, 20, reason: entry.key);
        expect(isDescriptionSufficient(text), isTrue, reason: entry.key);
      });
    }
  });

  group('Dart SDK trim behaviour the cross-language agreement rests on', () {
    // The API's trim set is Dart's — Unicode White_Space plus U+FEFF — written
    // out by hand. Nothing else in this repository proves the SDK half of that
    // claim, and if it ever stops holding the two rules disagree.
    test('String.trim() removes U+FEFF', () {
      expect('\u{FEFF}a\u{FEFF}'.trim(), 'a');
    });

    test('String.trim() leaves U+001C-U+001F alone', () {
      for (var point = 0x1C; point <= 0x1F; point++) {
        final separator = String.fromCharCode(point);
        expect(
          '${separator}a$separator'.trim(),
          '${separator}a$separator',
          reason: 'U+${point.toRadixString(16).toUpperCase().padLeft(4, '0')}',
        );
      }
    });
  });
}
