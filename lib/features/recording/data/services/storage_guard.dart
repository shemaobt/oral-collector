import '../../../../core/platform/disk_space.dart' as disk_space;

enum PreStartSeverity { ok, warn, refuse }

enum DuringSeverity { ok, critical, forceStop }

class StorageCheck<S> {
  const StorageCheck({
    required this.severity,
    required this.freeBytes,
    required this.estimatedSeconds,
  });

  final S severity;
  final int freeBytes;
  final int estimatedSeconds;
}

class StorageGuard {
  static const int kBytesPerSec = 24 * 1024;

  static const int kWarnThresholdBytes = 500 * 1024 * 1024;
  static const int kRefuseThresholdBytes = 50 * 1024 * 1024;
  static const int kCriticalThresholdBytes = 100 * 1024 * 1024;
  static const int kForceStopThresholdBytes = 20 * 1024 * 1024;

  Future<StorageCheck<PreStartSeverity>> checkBeforeStart() async {
    final free = await disk_space.getFreeBytes();
    final severity = free < kRefuseThresholdBytes
        ? PreStartSeverity.refuse
        : free < kWarnThresholdBytes
        ? PreStartSeverity.warn
        : PreStartSeverity.ok;
    return StorageCheck<PreStartSeverity>(
      severity: severity,
      freeBytes: free,
      estimatedSeconds: _estimateSeconds(free),
    );
  }

  Future<StorageCheck<DuringSeverity>> checkDuring() async {
    final free = await disk_space.getFreeBytes();
    final severity = free < kForceStopThresholdBytes
        ? DuringSeverity.forceStop
        : free < kCriticalThresholdBytes
        ? DuringSeverity.critical
        : DuringSeverity.ok;
    return StorageCheck<DuringSeverity>(
      severity: severity,
      freeBytes: free,
      estimatedSeconds: _estimateSeconds(free),
    );
  }

  int _estimateSeconds(int freeBytes) {
    if (freeBytes <= 0) return 0;
    return freeBytes ~/ kBytesPerSec;
  }
}
