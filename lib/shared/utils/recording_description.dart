import 'package:characters/characters.dart';

/// How much description a recording must carry before it can be saved.
///
/// Counted in extended grapheme clusters (UAX #29) — what a person perceives as
/// one character — so a Devanagari matra, an Arabic diacritic and an emoji ZWJ
/// sequence each cost what they look like they cost, and no writing system is
/// charged more than another for the same amount of text.
///
/// The number is a first estimate; it will be tuned against real field data.
/// This is the only place it appears, on either side of the API contract.
const minDescriptionGraphemes = 20;

/// Whether [value] says enough about a recording to be worth storing.
///
/// ponytail: the cross-repo rule normalizes to NFC first; Dart ships no
/// Unicode normalizer and this project has no dependency that does. Grapheme
/// cluster counts are invariant under NFC (composition only ever merges a base
/// with marks that already cluster with it), so the count agrees with the
/// Python side regardless. Add a normalizer only if the rule ever grows a
/// comparison that is not a count.
bool isDescriptionSufficient(String? value) =>
    (value ?? '').trim().characters.length >= minDescriptionGraphemes;
