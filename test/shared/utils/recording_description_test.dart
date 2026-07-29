// ENG-354: a recording needs a real description, measured in the units a
// person perceives as characters (extended grapheme clusters, UAX #29) rather
// than UTF-16 code units. The writing-system cases below are the point of the
// suite: every one of them would pass a `String.length >= 20` check while the
// user has typed far fewer characters than the rule asks for.
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/utils/recording_description.dart';

/// One perceived character each, but more than one UTF-16 code unit.
const _devanagari = 'की'; // क + ी (dependent vowel sign)
const _arabic = 'بَ'; // ب + fatha
const _cjk = '𠮷'; // outside the BMP: a surrogate pair
const _family = '👨‍👩‍👧‍👦'; // ZWJ sequence: 4 people, 11 code units

String _repeat(String cluster, int times) => cluster * times;

void main() {
  group('length boundary', () {
    test('a null description is not sufficient', () {
      expect(isDescriptionSufficient(null), isFalse);
    });

    test('an empty description is not sufficient', () {
      expect(isDescriptionSufficient(''), isFalse);
    });

    test('whitespace only is not sufficient', () {
      expect(isDescriptionSufficient('   \t\n  '), isFalse);
    });

    test('one below the threshold is not sufficient', () {
      expect(isDescriptionSufficient(_repeat('a', 19)), isFalse);
    });

    test('exactly at the threshold is sufficient', () {
      expect(isDescriptionSufficient(_repeat('a', 20)), isTrue);
    });

    test('surrounding whitespace does not pad a short description', () {
      expect(
        isDescriptionSufficient('          ${_repeat('a', 19)}   '),
        isFalse,
      );
    });

    test('surrounding whitespace does not disqualify a long enough one', () {
      expect(isDescriptionSufficient('\n  ${_repeat('a', 20)}  \n'), isTrue);
    });
  });

  group('counts what the reader sees, not code units', () {
    test('Devanagari matras do not count as separate characters', () {
      final short = _repeat(_devanagari, 19);
      expect(short.length, greaterThan(minDescriptionGraphemes));
      expect(isDescriptionSufficient(short), isFalse);
      expect(isDescriptionSufficient(_repeat(_devanagari, 20)), isTrue);
    });

    test('Arabic diacritics do not count as separate characters', () {
      final short = _repeat(_arabic, 19);
      expect(short.length, greaterThan(minDescriptionGraphemes));
      expect(isDescriptionSufficient(short), isFalse);
      expect(isDescriptionSufficient(_repeat(_arabic, 20)), isTrue);
    });

    test('a CJK character outside the BMP counts once, not twice', () {
      final short = _repeat(_cjk, 19);
      expect(short.length, greaterThan(minDescriptionGraphemes));
      expect(isDescriptionSufficient(short), isFalse);
      expect(isDescriptionSufficient(_repeat(_cjk, 20)), isTrue);
    });

    test('an emoji ZWJ sequence counts as one character', () {
      final short = _repeat(_family, 19);
      expect(short.length, greaterThan(minDescriptionGraphemes));
      expect(isDescriptionSufficient(short), isFalse);
      expect(isDescriptionSufficient(_repeat(_family, 20)), isTrue);
    });
  });
}
