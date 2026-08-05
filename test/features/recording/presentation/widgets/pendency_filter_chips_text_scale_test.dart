// The pendency shortcut row must survive a large system font. It scrolls
// horizontally, so width is not the risk — the chips growing taller than
// whatever the list later gives the row is.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/data/providers.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/domain/repositories/project_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pendency_filter_chips.dart';

import '../../../../support/text_scale.dart';

class _FakeRecordingsListNotifier extends RecordingsListNotifier {
  @override
  RecordingsListState build() => const RecordingsListState();
}

/// Counts present: the badge is the part that competes with the label for
/// width, so an empty aggregate would test the easier layout.
class _StatsRepo implements ProjectRepository {
  @override
  Future<ProjectStats> getProjectStats(String projectId) async =>
      const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 128,
          'insufficient_description': 64,
          'missing_storyteller': 32,
        },
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected in test');
}

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    overrides: [
      projectRepositoryProvider.overrideWithValue(_StatsRepo()),
      recordingsListNotifierProvider.overrideWith(
        _FakeRecordingsListNotifier.new,
      ),
    ],
    child: const Align(
      alignment: Alignment.topCenter,
      child: PendencyFilterChips(projectId: 'p1'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('pendency filter chips have no overflow at ${scale}x', (
      tester,
    ) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
