import 'dart:async';

class BackgroundSyncService {
  Timer? _webTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _startWebTimer();
  }

  void _startWebTimer() {
    _webTimer?.cancel();
    _webTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _onWebTimerTick();
    });
  }

  void Function()? onWebSyncRequested;

  void _onWebTimerTick() {
    onWebSyncRequested?.call();
  }

  void dispose() {
    _webTimer?.cancel();
    _webTimer = null;
    _initialized = false;
  }
}
