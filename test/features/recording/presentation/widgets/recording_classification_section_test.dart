import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_classification_section.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

const _testColors = AppColorSet(
  primary: Color(0xFF000000),
  accent: Color(0xFFBE4A01),
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF222222),
  card: Color(0xFFEEEEEE),
  surfaceAlt: Color(0xFFDDDDDD),
  secondary: Color(0xFF333333),
  info: Color(0xFF444444),
  infoText: Color(0xFF555555),
  success: Color(0xFF008800),
  successText: Color(0xFF005500),
  onPrimary: Color(0xFFFFFFFF),
  chipSurface: Color(0xFFFFFFFF),
  border: Color(0xFFCCCCCC),
  error: Color(0xFFAA0000),
  warning: Color(0xFFFFAA00),
);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  final l10n = AppLocalizationsEn();
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<LocalRecordingEntity> seed({
    String? splitFromId,
    int? splitIndex,
    int? splitSegmentCount,
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('rec-1'),
        projectId: const Value('p'),
        genreId: const Value('g'),
        title: const Value('Story'),
        durationSeconds: const Value(10),
        fileSizeBytes: const Value(1),
        format: const Value('m4a'),
        localFilePath: const Value('/a.m4a'),
        recordedAt: Value(DateTime.utc(2026, 1, 1)),
        splitFromId: Value(splitFromId),
        splitIndex: Value(splitIndex),
        splitSegmentCount: Value(splitSegmentCount),
      ),
    );
    return localRecordingToEntity((await repo.getRecordingById('rec-1'))!);
  }

  RecordingClassificationSection section(
    LocalRecordingEntity rec, {
    bool isUnclassified = false,
    bool hasSecondary = false,
    bool canEdit = true,
    String secondaryBreadcrumb = '',
    VoidCallback? onEditSecondary,
    VoidCallback? onClearSecondary,
  }) => RecordingClassificationSection(
    recording: rec,
    theme: ThemeData.light(),
    colors: _testColors,
    genreBreadcrumb: 'Tales > Myths',
    registerName: null,
    isUnclassified: isUnclassified,
    hasSecondary: hasSecondary,
    secondaryBreadcrumb: secondaryBreadcrumb,
    secondaryRegisterName: null,
    canEdit: canEdit,
    onEditDetails: () {},
    onEditSecondary: onEditSecondary ?? () {},
    onClearSecondary: onClearSecondary ?? () {},
  );

  testWidgets('renders the genre breadcrumb', (tester) async {
    final rec = await seed();
    await tester.pumpWidget(_wrap(section(rec)));

    expect(find.text('Tales > Myths'), findsOneWidget);
  });

  testWidgets(
    'shows the secondary card with its breadcrumb when hasSecondary',
    (tester) async {
      final rec = await seed();
      await tester.pumpWidget(
        _wrap(
          section(
            rec,
            hasSecondary: true,
            secondaryBreadcrumb: 'Songs > Lullaby',
          ),
        ),
      );

      expect(find.text(l10n.recording_alsoClassifiedAs), findsOneWidget);
      expect(find.text('Songs > Lullaby'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the add-alternative button when editable and no secondary',
    (tester) async {
      final rec = await seed();
      await tester.pumpWidget(_wrap(section(rec, canEdit: true)));

      expect(find.text(l10n.recording_addAlternative), findsOneWidget);
    },
  );

  testWidgets('hides the add-alternative button when not editable', (
    tester,
  ) async {
    final rec = await seed();
    await tester.pumpWidget(_wrap(section(rec, canEdit: false)));

    expect(find.text(l10n.recording_addAlternative), findsNothing);
  });

  testWidgets('shows the split indicator when splitFromId is set', (
    tester,
  ) async {
    final rec = await seed(
      splitFromId: 'parent',
      splitIndex: 0,
      splitSegmentCount: 3,
    );
    await tester.pumpWidget(_wrap(section(rec)));

    expect(find.text(l10n.recording_partOf(1, 3)), findsOneWidget);
  });

  testWidgets('tapping clear in the secondary card fires onClearSecondary', (
    tester,
  ) async {
    var calls = 0;
    final rec = await seed();
    await tester.pumpWidget(
      _wrap(
        section(
          rec,
          hasSecondary: true,
          canEdit: true,
          onClearSecondary: () => calls++,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();

    expect(calls, 1);
  });
}
