/// The untitled-recording fallback has to read as a clock, in the reader's own
/// convention. A hard-coded 24-hour clock is wrong in every locale that does
/// not use one, and the string is the only thing identifying the recording.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oral_collector/shared/utils/format.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Local, not UTC: formatWeekdayTime renders what it is handed.
  final afternoon = DateTime(2026, 3, 10, 16, 20, 8);

  group('formatWeekdayTime', () {
    test('en gets the 12-hour clock its locale asks for', () {
      final formatted = formatWeekdayTime(afternoon, 'en');

      expect(formatted, startsWith('Tuesday'));
      expect(formatted, contains('4:20:08'));
      expect(formatted, contains('PM'));
      expect(formatted, isNot(contains('16:20')));
    });

    test('pt keeps the 24-hour clock it asks for', () {
      final formatted = formatWeekdayTime(afternoon, 'pt');

      expect(formatted, contains('16:20:08'));
    });

    test('seconds survive, so recordings from one session stay distinct', () {
      final oneSecondLater = DateTime(2026, 3, 10, 16, 20, 9);

      expect(
        formatWeekdayTime(afternoon, 'en'),
        isNot(formatWeekdayTime(oneSecondLater, 'en')),
      );
    });
  });
}
