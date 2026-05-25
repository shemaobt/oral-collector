import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const uploadServiceId = 1003;

/// Task handler for the upload foreground service. The upload loop itself runs
/// in the main isolate (kept alive by the foreground service); this handler has
/// no work to do, it only satisfies the plugin's callback contract.
class UploadTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

@pragma('vm:entry-point')
void startUploadTaskCallback() {
  FlutterForegroundTask.setTaskHandler(UploadTaskHandler());
}
