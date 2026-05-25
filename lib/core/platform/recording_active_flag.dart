import 'package:shared_preferences/shared_preferences.dart';

import '../config/recording_config.dart';

class RecordingActiveFlag {
  const RecordingActiveFlag();

  Future<void> markActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RecordingConfig.recordingActiveFlagKey, true);
  }

  Future<void> markInactive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RecordingConfig.recordingActiveFlagKey, false);
  }

  Future<bool> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(RecordingConfig.recordingActiveFlagKey) ?? false;
  }
}
