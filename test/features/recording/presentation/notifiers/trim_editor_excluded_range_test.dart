import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/joined_audio_exporter.dart';
import 'package:oral_collector/features/recording/data/services/local_segment_exporter.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_notifier.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

import '../../../../support/system_ffmpeg.dart';

const _recordingId = 'rec-1';
const _total = Duration(seconds: 60);

class _QuietSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState();
  @override
  Future<void> processQueue() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late String sourcePath;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  JoinKeptRangesRequest? joinRequest;
  ExportLocalSegmentsRequest? exportRequest;

  setUp(() async {
    joinRequest = null;
    exportRequest = null;
    docs = Directory.systemTemp.createTempSync('trim_excluded_range_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    sourcePath = '${docs.path}/story.m4a';
    await writeToneM4a(sourcePath, seconds: 60);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value(_recordingId),
        projectId: const Value('proj'),
        genreId: const Value('g0'),
        title: const Value('Story'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: Value(File(sourcePath).lengthSync()),
        format: const Value('m4a'),
        localFilePath: Value(sourcePath),
        uploadStatus: const Value('local'),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    docs.deleteSync(recursive: true);
  });

  Future<TrimEditorNotifier> openEditor() async {
    final c = ProviderContainer(
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        syncNotifierProvider.overrideWith(_QuietSyncNotifier.new),
        joinedAudioExporterProvider.overrideWithValue((request) {
          joinRequest = request;
          return exportJoinedKeptRanges(request, runner: runSystemFFmpeg);
        }),
        localSegmentExporterProvider.overrideWithValue((request) {
          exportRequest = request;
          return exportLocalSegments(request, runner: runSystemFFmpeg);
        }),
      ],
    );
    addTearDown(c.dispose);
    final notifier = c.read(trimEditorProvider(_recordingId).notifier);
    await notifier.load(isWeb: false);
    notifier.completeLoad(totalDuration: _total);
    return notifier;
  }

  double fraction(num seconds) => seconds / _total.inSeconds;

  bool exclude(TrimEditorNotifier n, num from, num to) =>
      n.confirmExcludedRange(
        startFraction: fraction(from),
        endFraction: fraction(to),
      );

  List<(double, double)> asSeconds(List<KeptRange> ranges) => [
    for (final r in ranges) (r.startSeconds, r.endSeconds),
  ];

  test('Confirming handles dragged to 18 s and 32 s excludes that range '
      'without adding a split mark', () async {
    final n = await openEditor();

    final accepted = exclude(n, 18, 32);

    final state = n.state;
    expect(accepted, isTrue);
    expect(state.excludedRanges, hasLength(1));
    expect(state.excludedRanges.single.startFraction * 60, closeTo(18, 0.001));
    expect(state.excludedRanges.single.endFraction * 60, closeTo(32, 0.001));
    expect(state.splitPoints, isEmpty);
    expect(state.segmentCount, 1);
  });

  test(
    'Removing the stretch keeps 0-18 s and 32-60 s of the recording',
    () async {
      final n = await openEditor();
      exclude(n, 18, 32);

      final outcome = await n.saveSplit(
        isWeb: false,
        localeTag: 'pt',
        mode: TrimSaveMode.removeStretch,
      );

      expect(outcome, isA<TrimSaveSucceeded>());
      expect(asSeconds(joinRequest!.keptRanges), [(0.0, 18.0), (32.0, 60.0)]);
    },
  );

  test('Split marks and the segment card\'s exclude toggle keep working '
      'beside an excluded range', () async {
    final n = await openEditor();
    n.setSplitPoints([fraction(40)]);
    exclude(n, 18, 32);

    final excluded = n.toggleExclude(1);
    final afterExclude = n.state.excludedSegments;
    final restored = n.toggleExclude(1);

    expect(excluded, isTrue);
    expect(afterExclude, {1});
    expect(restored, isTrue);
    expect(n.state.excludedSegments, isEmpty);
    expect(n.state.splitPoints, [fraction(40)]);
    expect(n.state.excludedRanges, hasLength(1));
  });

  test('Keeping the segments separate cuts one recording per kept part, '
      'each with its segment\'s taxonomy override', () async {
    final n = await openEditor();
    n.setSplitPoints([fraction(40)]);
    n.setSegmentTaxonomy(
      index: 0,
      applyToAll: false,
      genreId: 'g9',
      subcategoryId: null,
      registerId: null,
    );
    exclude(n, 18, 32);

    await n.saveSplit(isWeb: false, localeTag: 'pt', mode: TrimSaveMode.split);

    final parts = [
      for (final s in exportRequest!.segments)
        (s.startSeconds, s.endSeconds, s.genreOverride),
    ];
    expect(parts, [(0.0, 18.0, 'g9'), (32.0, 40.0, 'g9'), (40.0, 60.0, 'g0')]);
  });

  test('Two overlapping ranges count as one excluded stretch', () async {
    final n = await openEditor();
    exclude(n, 10, 30);
    exclude(n, 20, 40);

    final outcome = await n.saveSplit(
      isWeb: false,
      localeTag: 'pt',
      mode: TrimSaveMode.removeStretch,
    );

    expect((outcome as TrimSaveSucceeded).excludedCount, 1);
    expect(asSeconds(joinRequest!.keptRanges), [(0.0, 10.0), (40.0, 60.0)]);
  });

  List<(double, double)> keptSeconds(TrimEditorNotifier n) => [
    for (final p in n.state.keptParts)
      (
        double.parse((p.startFraction * 60).toStringAsFixed(3)),
        double.parse((p.endFraction * 60).toStringAsFixed(3)),
      ),
  ];

  test('Two ranges 100 ms apart leave no kept part between them', () async {
    final n = await openEditor();
    exclude(n, 10, 20);

    exclude(n, 20.1, 30);

    expect(keptSeconds(n), [(0.0, 10.0), (30.0, 60.0)]);
  });

  test('A range ending 100 ms before the end leaves no tail', () async {
    final n = await openEditor();

    exclude(n, 20, 59.9);

    expect(keptSeconds(n), [(0.0, 20.0)]);
  });

  test('A range starting 100 ms after the start leaves no head', () async {
    final n = await openEditor();

    exclude(n, 0.1, 30);

    expect(keptSeconds(n), [(30.0, 60.0)]);
  });

  test('A range ending 50 ms before a split mark leaves no part beside the '
      'mark', () async {
    final n = await openEditor();
    n.setSplitPoints([fraction(40)]);

    exclude(n, 20, 39.95);

    expect(keptSeconds(n), [(0.0, 20.0), (40.0, 60.0)]);
  });

  test('A kept part of exactly 250 ms is left alone', () async {
    final n = await openEditor();

    exclude(n, 20, 59.75);

    expect(keptSeconds(n), [(0.0, 20.0), (59.75, 60.0)]);
  });
}
