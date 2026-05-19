import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const recordingStopEventKey = 'stop_recording';
const recordingStopButtonId = 'recording_stop';
const recordingServiceId = 1002;

class RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == recordingStopButtonId) {
      FlutterForegroundTask.sendDataToMain(recordingStopEventKey);
    }
  }
}

@pragma('vm:entry-point')
void startRecordingTaskCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}
