import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/ffmpeg_ops.dart' as ffmpeg;
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../repositories/local_recording_repository.dart';

/// One kept segment's geometry + per-child taxonomy, resolved by the caller
/// before any platform IO. Times are in seconds; a boost-only save passes a
/// single segment spanning the whole recording.
class SegmentExportSpec {
  const SegmentExportSpec({
    required this.startSeconds,
    required this.endSeconds,
    this.genreOverride,
    this.subcategoryOverride,
    this.registerOverride,
  });

  final double startSeconds;
  final double endSeconds;
  final String? genreOverride;
  final String? subcategoryOverride;
  final String? registerOverride;
}

/// Bundles the per-call inputs to [exportLocalSegments] (everything the caller
/// resolves before any platform IO). Grouping them keeps the function's
/// parameter list small; the injectable IO seams stay as named parameters.
class ExportLocalSegmentsRequest {
  const ExportLocalSegmentsRequest({
    required this.sourceFilePath,
    required this.segments,
    required this.gainDb,
    required this.boostOnly,
    required this.originalTitle,
    required this.parentGenreId,
  });

  final String sourceFilePath;
  final List<SegmentExportSpec> segments;
  final double gainDb;
  final bool boostOnly;
  final String originalTitle;
  final String parentGenreId;
}

/// Runs ffmpeg per kept segment and returns the [SplitSegmentSpec]s ready for
/// `RecordingSplitPersister`. Isolated from the widget so the orchestration can
/// be unit-tested without a device (ffmpeg/file-length/clock/documents-dir are
/// injectable). Kept free of a direct `dart:io` import so it stays web-safe to
/// compile — the native save path is the only caller at runtime.
typedef LocalSegmentExporter =
    Future<List<SplitSegmentSpec>> Function(ExportLocalSegmentsRequest request);

Future<List<SplitSegmentSpec>> exportLocalSegments(
  ExportLocalSegmentsRequest request, {
  ffmpeg.FFmpegRunner runner = ffmpeg.executeFFmpegCommand,
  Future<int> Function(String path) fileLength = file_ops.fileLength,
  DateTime Function() clock = DateTime.now,
  Future<String> Function() documentsDirectoryPath =
      _defaultDocumentsDirectoryPath,
}) async {
  final ExportLocalSegmentsRequest(
    :sourceFilePath,
    :segments,
    :gainDb,
    :boostOnly,
    :originalTitle,
    :parentGenreId,
  ) = request;
  final dirPath = await documentsDirectoryPath();
  final now = clock();
  final keptTotal = segments.length;
  final needReencode = gainDb.abs() > 0.01;

  final specs = <SplitSegmentSpec>[];
  for (var k = 0; k < keptTotal; k++) {
    final seg = segments[k];
    final segDuration = seg.endSeconds - seg.startSeconds;
    final outputPath = '$dirPath/split_${now.millisecondsSinceEpoch}_$k.m4a';

    final String command;
    if (boostOnly) {
      command =
          '-y -i "$sourceFilePath" '
          '-af "volume=${gainDb.toStringAsFixed(2)}dB" '
          '-c:a aac -b:a 128k "$outputPath"';
    } else if (needReencode) {
      command =
          '-y -i "$sourceFilePath" -ss ${seg.startSeconds} -to ${seg.endSeconds} '
          '-af "volume=${gainDb.toStringAsFixed(2)}dB" '
          '-c:a aac -b:a 128k "$outputPath"';
    } else {
      command =
          '-y -i "$sourceFilePath" -ss ${seg.startSeconds} -to ${seg.endSeconds} '
          '-c copy "$outputPath"';
    }

    final success = await runner(command);
    if (!success) {
      throw Exception('FFmpeg failed on segment ${k + 1}');
    }

    final fileSize = await fileLength(outputPath);

    specs.add(
      SplitSegmentSpec(
        id: '${now.millisecondsSinceEpoch}_${k}_${parentGenreId.hashCode}',
        title: keptTotal == 1
            ? originalTitle
            : '$originalTitle (${k + 1}/$keptTotal)',
        localFilePath: outputPath,
        durationSeconds: segDuration,
        fileSizeBytes: fileSize,
        genreOverride: seg.genreOverride,
        subcategoryOverride: seg.subcategoryOverride,
        registerOverride: seg.registerOverride,
      ),
    );
  }
  return specs;
}

Future<String> _defaultDocumentsDirectoryPath() async =>
    (await getApplicationDocumentsDirectory()).path;

final localSegmentExporterProvider = Provider<LocalSegmentExporter>(
  (_) => exportLocalSegments,
);
