import 'package:disk_space_plus/disk_space_plus.dart';

final _plugin = DiskSpacePlus();

const int _bytesPerMegabyte = 1024 * 1024;

Future<int> getFreeBytes() async {
  final mb = await _plugin.getFreeDiskSpace;
  if (mb == null) return 0;
  return (mb * _bytesPerMegabyte).round();
}

Future<int> getTotalBytes() async {
  final mb = await _plugin.getTotalDiskSpace;
  if (mb == null) return 0;
  return (mb * _bytesPerMegabyte).round();
}
