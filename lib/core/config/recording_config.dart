abstract class RecordingConfig {
  static const appGroupId = 'group.com.shema.oralCollector';
  static const liveActivityUrlScheme = 'oralcollector';
  static const notificationIconMetadata =
      'com.shema.oralCollector.recording_notification_icon';
  static const recordingActiveFlagKey =
      'com.shema.oralCollector.is_recording_active';

  /// Marks that the one-shot recovery of sessions stranded in a terminal
  /// status by the ENG-521 defect has already run on this device (ENG-522).
  static const discardedAudioRecoveryDoneKey =
      'com.shema.oralCollector.discarded_audio_recovery_done';
}
