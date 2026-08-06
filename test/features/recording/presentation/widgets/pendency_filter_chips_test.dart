/// The quick pendency filter on the recordings list (design: Card V3).
///
/// The sheet already owns this filter; this row is a shortcut in front of it,
/// so the two must never disagree — both read and write the same field on the
/// list notifier, and the tests below are what holds that.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_notifier.dart';
import 'package:oral_collector/features/project/presentation/notifiers/project_state.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pendency_filter_chips.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../../support/text_scale.dart';

final _l10n = AppLocalizationsEn();

const _project = Project(id: 'p1', name: 'Kwanga stories', languageId: 'l1');

/// Remembers the `review_flag` of every listing, so a test can check the
/// filter reached the server rather than only the local state.
class _RecordingApi implements RecordingApiRepository {
  final askedFlags = <String?>[];

  @override
  Future<List<ServerRecording>> listRecordings(
    String projectId, {
    int offset = 0,
    int limit = 50,
    String? userId,
    String? storytellerId,
    String? uploadStatus,
    String? title,
    String? reviewFlag,
  }) async {
    askedFlags.add(reviewFlag);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeLocal implements LocalRecordingRepository {
  @override
  Future<List<LocalRecording>> getAllRecordings(String projectId) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _FakeProjectNotifier extends ProjectNotifier {
  @override
  ProjectState build() => const ProjectState(activeProject: _project);
}

/// Answers the aggregate, or refuses to — the field's offline case.
class _StatsRepo implements ProjectRepository {
  _StatsRepo(this._stats);

  final ProjectStats? _stats;

  @override
  Future<ProjectStats> getProjectStats(String projectId) async {
    final stats = _stats;
    if (stats == null) throw Exception('no network');
    return stats;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

class _SyncNotifierAt extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true);

  @override
  Future<void> processQueue() async {}
}

void main() {
  late _RecordingApi api;

  setUp(() => api = _RecordingApi());

  /// The real list notifier throughout: the question is what the row does to
  /// the filter the list holds, and a fake would answer a different one.
  Future<ProviderContainer> pumpRow(
    WidgetTester tester, {
    ProjectStats? stats,
    PendencyKind? initial,
  }) async {
    await pumpAtTextScale(
      tester,
      overrides: [
        recordingApiRepositoryProvider.overrideWithValue(api),
        localRecordingRepositoryProvider.overrideWithValue(_FakeLocal()),
        projectRepositoryProvider.overrideWithValue(_StatsRepo(stats)),
        projectNotifierProvider.overrideWith(_FakeProjectNotifier.new),
        syncNotifierProvider.overrideWith(_SyncNotifierAt.new),
      ],
      child: const PendencyFilterChips(projectId: 'p1'),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PendencyFilterChips)),
    );
    if (initial != null) {
      await container
          .read(recordingsListNotifierProvider.notifier)
          .setReviewFlagFilter(initial);
    }
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pumpAndSettle();
  }

  testWidgets('the row offers the way back plus every pendency the app can '
      'act on', (tester) async {
    await pumpRow(tester);

    expect(find.widgetWithText(ChoiceChip, _l10n.filter_pendencyAll), findsOne);
    expect(
      find.widgetWithText(ChoiceChip, _l10n.recording_pendencyClassification),
      findsOne,
    );
    expect(
      find.widgetWithText(ChoiceChip, _l10n.recording_pendencyDescription),
      findsOne,
    );
    expect(
      find.widgetWithText(ChoiceChip, _l10n.recording_pendencyStoryteller),
      findsOne,
    );
  });

  testWidgets('picking a pendency asks the server for exactly that flag', (
    tester,
  ) async {
    final container = await pumpRow(tester);

    await tapChip(tester, _l10n.recording_pendencyStoryteller);

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      PendencyKind.storyteller,
    );
    expect(api.askedFlags.last, 'missing_storyteller');
  });

  testWidgets('picking "all" gives the whole project back', (tester) async {
    final container = await pumpRow(
      tester,
      initial: PendencyKind.classification,
    );

    await tapChip(tester, _l10n.filter_pendencyAll);

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      isNull,
    );
    expect(api.askedFlags.last, isNull);
  });

  testWidgets('the row reads the filter the list already carries, so the '
      'sheet and the shortcut cannot disagree', (tester) async {
    await pumpRow(tester, initial: PendencyKind.description);

    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, _l10n.recording_pendencyDescription),
    );
    final other = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, _l10n.filter_pendencyAll),
    );

    expect(selected.selected, isTrue);
    expect(other.selected, isFalse);
  });

  testWidgets('each pendency says how many recordings are waiting on it', (
    tester,
  ) async {
    await pumpRow(
      tester,
      stats: const ProjectStats(
        totalRecordings: 40,
        reviewFlagCounts: {
          'missing_classification': 7,
          'insufficient_description': 2,
          'missing_storyteller': 5,
        },
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(
          ChoiceChip,
          _l10n.recording_pendencyClassification,
        ),
        matching: find.text('7'),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(
          ChoiceChip,
          _l10n.recording_pendencyDescription,
        ),
        matching: find.text('2'),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(
          ChoiceChip,
          _l10n.recording_pendencyStoryteller,
        ),
        matching: find.text('5'),
      ),
      findsOne,
    );
  });

  testWidgets('a pendency nobody carries is absent from the aggregate, and '
      'reads as zero rather than as unknown', (tester) async {
    await pumpRow(
      tester,
      stats: const ProjectStats(
        totalRecordings: 40,
        reviewFlagCounts: {'missing_storyteller': 5},
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(
          ChoiceChip,
          _l10n.recording_pendencyClassification,
        ),
        matching: find.text('0'),
      ),
      findsOne,
    );
  });

  testWidgets('an aggregate that never answers leaves the filter usable '
      'without inventing counts', (tester) async {
    final container = await pumpRow(tester);

    expect(find.text('0'), findsNothing);

    await tapChip(tester, _l10n.recording_pendencyClassification);

    expect(
      container.read(recordingsListNotifierProvider).selectedReviewFlag,
      PendencyKind.classification,
    );
  });

  group('the density the design package specifies', () {
    testWidgets('a chip is a pill, not a Material chip at its default size', (
      tester,
    ) async {
      await pumpRow(tester);

      final chip = tester.getSize(
        find.widgetWithText(ChoiceChip, _l10n.filter_pendencyAll),
      );

      // Material's default ChoiceChip is a 32px label box inside a 48px tap
      // target, which is what made the row read as oversized; the package's
      // pill is ~26px. A ceiling of 30 is below the Material floor, so it
      // fails the day any of the overrides that buy the density is dropped —
      // a ceiling at the measured height would only pin today's number.
      expect(chip.height, lessThan(30));
    });

    testWidgets('the count is bare bold text, with no capsule of its own', (
      tester,
    ) async {
      await pumpRow(
        tester,
        stats: const ProjectStats(reviewFlagCounts: {'missing_storyteller': 5}),
      );

      final count = find.descendant(
        of: find.widgetWithText(
          ChoiceChip,
          _l10n.recording_pendencyStoryteller,
        ),
        matching: find.text('5'),
      );

      expect(count, findsOne);
      // The package draws the count as bold text beside the label. A box of
      // its own is what made the chip wider than the design.
      expect(
        find.ancestor(of: count, matching: find.byType(Container)),
        findsNothing,
      );
      expect(tester.widget<Text>(count).style?.fontWeight, FontWeight.w800);
    });

    testWidgets('each pendency chip carries the glyph of the field it names, '
        'and "all" carries none', (tester) async {
      await pumpRow(tester);

      for (final glyph in [
        LucideIcons.tag,
        LucideIcons.fileText,
        LucideIcons.userMinus,
      ]) {
        expect(find.byIcon(glyph), findsOne, reason: '$glyph missing');
      }
      expect(
        find.descendant(
          of: find.widgetWithText(ChoiceChip, _l10n.filter_pendencyAll),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });
  });
}
