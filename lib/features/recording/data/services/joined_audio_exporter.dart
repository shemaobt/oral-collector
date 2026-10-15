import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/platform/file_source.dart';
import '../../domain/audible_gain.dart';
import 'audio_metadata/mp4_box_probe.dart';

class KeptRange {
  const KeptRange({required this.startSeconds, required this.endSeconds});

  final double startSeconds;
  final double endSeconds;
}

class JoinKeptRangesRequest {
  const JoinKeptRangesRequest({
    required this.sourceFilePath,
    required this.keptRanges,
    required this.gainDb,
  });

  final String sourceFilePath;
  final List<KeptRange> keptRanges;
  final double gainDb;
}

class EditedAudio {
  const EditedAudio({
    required this.localFilePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  final String localFilePath;
  final double durationSeconds;
  final int fileSizeBytes;

  String get format => localFilePath.split('.').last;
}

typedef JoinedAudioExporter =
    Future<EditedAudio> Function(JoinKeptRangesRequest request);

const double _durationToleranceSeconds = 0.25;

Future<EditedAudio> exportJoinedKeptRanges(
  JoinKeptRangesRequest request, {
  ffmpeg.FFmpegRunner runner = ffmpeg.executeFFmpegCommand,
  Future<int> Function(String path) fileLength = file_ops.fileLength,
  DateTime Function() clock = DateTime.now,
  Future<String> Function() documentsDirectoryPath =
      _defaultDocumentsDirectoryPath,
}) async {
  final dirPath = await documentsDirectoryPath();
  final outputPath = '$dirPath/joined_${clock().millisecondsSinceEpoch}.m4a';
  final ok = await runner(
    '-y -i "${request.sourceFilePath}" '
    '-filter_complex "${_joinFilter(request)}" -map "[out]" '
    '-c:a aac -b:a 128k "$outputPath"',
  );
  if (!ok) throw Exception('FFmpeg failed joining the kept parts');

  final keptSeconds = request.keptRanges.fold<double>(
    0,
    (sum, r) => sum + (r.endSeconds - r.startSeconds),
  );
  final measured = await _measureSeconds(outputPath);
  if (measured == null ||
      (measured - keptSeconds).abs() > _durationToleranceSeconds) {
    throw Exception(
      'Joined audio lasts ${measured ?? 0} s, the kept parts $keptSeconds s',
    );
  }

  return EditedAudio(
    localFilePath: outputPath,
    durationSeconds: keptSeconds,
    fileSizeBytes: await fileLength(outputPath),
  );
}

Future<double?> _measureSeconds(String path) async {
  final source = FileSource.fromPath(
    path,
    name: path.split('/').last,
    length: await file_ops.fileLength(path),
  );
  try {
    final probed = await probeMp4Duration(source);
    return (probed?.hasDuration ?? false) ? probed!.durationSeconds : null;
  } finally {
    source.dispose();
  }
}

String _joinFilter(JoinKeptRangesRequest request) {
  final ranges = request.keptRanges;
  final trims = [
    for (var i = 0; i < ranges.length; i++)
      '[0:a]atrim=start=${ranges[i].startSeconds}:end=${ranges[i].endSeconds},'
          'asetpts=PTS-STARTPTS[k$i]',
  ];
  final inputs = [for (var i = 0; i < ranges.length; i++) '[k$i]'].join();
  final gain = isAudibleGain(request.gainDb)
      ? ',volume=${request.gainDb.toStringAsFixed(2)}dB'
      : '';
  return '${trims.join(';')};'
      '${inputs}concat=n=${ranges.length}:v=0:a=1$gain[out]';
}

Future<String> _defaultDocumentsDirectoryPath() async =>
    (await getApplicationDocumentsDirectory()).path;

final joinedAudioExporterProvider = Provider<JoinedAudioExporter>(
  (_) => exportJoinedKeptRanges,
);
