import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oral_collector/shared/utils/recording_title.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('resolveRecordingTitle', () {
    test('returns trimmed input when non-empty', () {
      final result = resolveRecordingTitle('  My Recording  ', locale: 'en');
      expect(result, 'My Recording');
    });

    test('returns default title when input is empty', () {
      final result = resolveRecordingTitle('', locale: 'en');
      expect(result, isNotEmpty);
      expect(result, defaultRecordingTitle(locale: 'en'));
    });

    test('returns default title when input is whitespace only', () {
      final result = resolveRecordingTitle('   ', locale: 'en');
      expect(result, defaultRecordingTitle(locale: 'en'));
    });

    test('returns default title when input is null', () {
      final result = resolveRecordingTitle(null, locale: 'en');
      expect(result, defaultRecordingTitle(locale: 'en'));
    });
  });

  group('isTitleTaken', () {
    test('is true for an exact match', () {
      expect(isTitleTaken(['Alpha', 'Beta'], 'Beta'), isTrue);
    });

    test('is false when nothing matches', () {
      expect(isTitleTaken(['Alpha', 'Beta'], 'Gamma'), isFalse);
    });

    // The deliberate part: raw equality, because the backend deduplicates on
    // the exact stored string. Trimming or case-folding here would disagree
    // with the 409 the server would answer with.
    test('is false when only whitespace or casing differs', () {
      expect(isTitleTaken(['Alpha'], ' Alpha'), isFalse);
      expect(isTitleTaken(['Alpha'], 'alpha'), isFalse);
      expect(isTitleTaken([' Alpha '], 'Alpha'), isFalse);
    });
  });
}
