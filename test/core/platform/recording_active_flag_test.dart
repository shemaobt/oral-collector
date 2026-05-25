import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oral_collector/core/config/recording_config.dart';
import 'package:oral_collector/core/platform/recording_active_flag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordingActiveFlag', () {
    test('read returns false when never set', () async {
      final flag = const RecordingActiveFlag();
      expect(await flag.read(), isFalse);
    });

    test('markActive then read returns true', () async {
      final flag = const RecordingActiveFlag();
      await flag.markActive();
      expect(await flag.read(), isTrue);
    });

    test('markInactive then read returns false', () async {
      final flag = const RecordingActiveFlag();
      await flag.markActive();
      await flag.markInactive();
      expect(await flag.read(), isFalse);
    });

    test('markActive twice is idempotent', () async {
      final flag = const RecordingActiveFlag();
      await flag.markActive();
      await flag.markActive();
      expect(await flag.read(), isTrue);
    });

    test('markInactive when never active does not throw', () async {
      final flag = const RecordingActiveFlag();
      await flag.markInactive();
      expect(await flag.read(), isFalse);
    });

    test('persists value across instances', () async {
      await const RecordingActiveFlag().markActive();
      expect(await const RecordingActiveFlag().read(), isTrue);
    });

    test('uses the documented RecordingConfig key', () async {
      await const RecordingActiveFlag().markActive();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(RecordingConfig.recordingActiveFlagKey), isTrue);
    });
  });
}
