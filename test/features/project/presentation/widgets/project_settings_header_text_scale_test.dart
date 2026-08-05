// ENG-180: ProjectSettingsHeader (SliverAppBar) must not overflow its fixed
// expanded height or its language row under large system fonts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_settings_header.dart';

import '../../../../support/text_scale.dart';

const _longName =
    'A Remarkably Long Project Title That Keeps Going And Going Indeed';
const _longLanguage =
    'Português Brasileiro Setentrional do Sertão Profundo e Distante';

const _project = Project(
  id: 'p1',
  name: _longName,
  languageId: 'l1',
  languageName: _longLanguage,
  languageCode: 'pt',
);

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: CustomScrollView(
      slivers: [
        ProjectSettingsHeader(project: _project, memberCount: 8, onBack: () {}),
      ],
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('does not overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }

  testWidgets('language name ellipsizes at 2.0x', (tester) async {
    await _pump(tester, 2.0);
    expect(
      tester.widget<Text>(find.text(_longLanguage)).overflow,
      TextOverflow.ellipsis,
    );
  });
}
