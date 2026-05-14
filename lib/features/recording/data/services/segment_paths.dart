abstract class SegmentPaths {
  static const _suffix = '.wav';
  static const _filePrefix = 'rec_';

  static String forSegment(String dirPath, String sessionId, int index) {
    final padded = index.toString().padLeft(3, '0');
    return '$dirPath/$_filePrefix${sessionId}_$padded$_suffix';
  }

  static String prefixFor(String dirPath, String sessionId) {
    return '$dirPath/$_filePrefix${sessionId}_';
  }

  static int? parseIndex(String path, String prefix) {
    if (!path.startsWith(prefix)) return null;
    if (!path.endsWith(_suffix)) return null;
    final rest = path.substring(prefix.length, path.length - _suffix.length);
    return int.tryParse(rest);
  }
}
