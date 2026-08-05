import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

LocalRecordingEntity _makeRecording({
  String id = 'rec-1',
  String uploadStatus = 'uploading',
  String? secondaryGenreId,
}) => LocalRecordingEntity(
  id: id,
  projectId: 'proj-1',
  genreId: 'genre-1',
  subcategoryId: null,
  title: 'Test recording',
  durationSeconds: 60.0,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/test.m4a',
  uploadStatus: uploadStatus,
  serverId: null,
  gcsUrl: null,
  registerId: null,
  secondaryGenreId: secondaryGenreId,
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: 0,
  resumableSessionUri: null,
  uploadedBytes: 0,
);

Widget _harness({
  required LocalRecordingEntity recording,
  required SyncState state,
}) {
  return ProviderScope(
    overrides: [
      syncNotifierProvider.overrideWith(() => _FakeSyncNotifier(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecordingCard(
          recording: recording,
          genreName: 'Folktale',
          onTap: () {},
        ),
      ),
    ),
  );
}

/// The status icon, reached through its tooltip. Going through the tooltip is
/// what ties "this state" to "this glyph" — `find.byIcon` would only prove
/// some icon exists somewhere on the card.
Icon _statusIconUnder(WidgetTester tester, String tooltip) =>
    tester.widget<Icon>(
      find.descendant(of: find.byTooltip(tooltip), matching: find.byType(Icon)),
    );

void main() {
  testWidgets('no progress bar when nothing is uploading', (tester) async {
    await tester.pumpWidget(
      _harness(recording: _makeRecording(), state: const SyncState()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('no progress bar when a different recording is uploading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(id: 'rec-1'),
        state: const SyncState(uploadingId: 'rec-2', syncProgress: 80),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'shows progress bar and percent when this recording is uploading',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          recording: _makeRecording(id: 'rec-1'),
          state: const SyncState(uploadingId: 'rec-1', syncProgress: 42),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the also-classified icon when the recording has a secondary '
    'classification',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          recording: _makeRecording(secondaryGenreId: 'genre-2'),
          state: const SyncState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.layers), findsOneWidget);
    },
  );

  testWidgets(
    'hides the also-classified icon when there is no secondary classification',
    (tester) async {
      await tester.pumpWidget(
        _harness(recording: _makeRecording(), state: const SyncState()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.layers), findsNothing);
    },
  );

  // The status chip lost its text in ENG-374 (card V3), so the label now rides
  // on the icon's tooltip and semantics. Both cases below still have to be
  // distinguishable from a generic failure — silently collapsing them into
  // "Failed" is what these tests exist to prevent.
  //
  // The label is asserted on the status icon itself rather than through
  // `find.bySemanticsLabel`: InkWell merges the whole card into one semantics
  // node, so a card-wide label match would also be satisfied by the pendency
  // chip — which in English renders the very same string for a missing
  // description.
  testWidgets('a title-conflict recording announces its own status', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'failed_conflict'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Name conflict'), findsOneWidget);
    expect(find.byTooltip('Failed'), findsNothing);
    expect(find.byTooltip('Local'), findsNothing);
    expect(
      _statusIconUnder(tester, 'Name conflict').semanticLabel,
      'Name conflict',
      reason: 'colour alone must not be what tells the two failures apart',
    );
  });

  testWidgets('a recording blocked on its description announces that', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'failed_description'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Description too short'), findsOneWidget);
    expect(find.byTooltip('Failed'), findsNothing);
    expect(find.byTooltip('Local'), findsNothing);
    expect(
      _statusIconUnder(tester, 'Description too short').semanticLabel,
      'Description too short',
    );
  });

  // These two are out of the upload queue for good (ENG-377), so the card is
  // where the user meets them. Falling through to "Local" would show a
  // recording that will never upload as one that simply has not yet.
  testWidgets('a recording that spent its retries announces that', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'failed_exhausted'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Attempts used up'), findsOneWidget);
    expect(find.byTooltip('Local'), findsNothing);
    expect(
      _statusIconUnder(tester, 'Attempts used up').semanticLabel,
      'Attempts used up',
    );
  });

  testWidgets('a recording whose audio file is gone announces that', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'failed_missing_file'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Audio file missing'), findsOneWidget);
    expect(find.byTooltip('Local'), findsNothing);
    expect(
      _statusIconUnder(tester, 'Audio file missing').semanticLabel,
      'Audio file missing',
    );
  });

  // The tooltip is only reachable by hover or long-press. A sighted user
  // glancing at the list gets shape and colour, and every blocked state shares
  // the colour, so the shape has to be what separates them.
  testWidgets('each blocked-upload state gets its own glyph', (tester) async {
    const states = {
      'failed': 'Failed',
      'failed_conflict': 'Name conflict',
      'failed_description': 'Description too short',
      'failed_exhausted': 'Attempts used up',
      'failed_missing_file': 'Audio file missing',
    };

    final glyphs = <String, IconData>{};
    for (final entry in states.entries) {
      await tester.pumpWidget(
        _harness(
          recording: _makeRecording(uploadStatus: entry.key),
          state: const SyncState(),
        ),
      );
      await tester.pumpAndSettle();
      glyphs[entry.key] = _statusIconUnder(tester, entry.value).icon!;
    }

    expect(glyphs.values.toSet(), hasLength(states.length));
  });

  testWidgets('the status tooltip hangs off a touchable target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'failed_conflict'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    // 13px of glyph is not a long-press target. The label is only reachable if
    // the thing carrying it is big enough to hit.
    final size = tester.getSize(find.byTooltip('Name conflict'));
    expect(size.width, greaterThanOrEqualTo(24));
    expect(size.height, greaterThanOrEqualTo(24));
  });

  testWidgets('the status label is no longer visible text', (tester) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(uploadStatus: 'uploaded'),
        state: const SyncState(),
      ),
    );
    await tester.pumpAndSettle();

    // The description only fits because the chip gave up its room. Bringing the
    // text back would take that room again.
    expect(find.text('Uploaded'), findsNothing);
  });
}
