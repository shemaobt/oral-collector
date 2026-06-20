// ENG-180: ProfileHeader displayName must ellipsize rather than overflow its
// row under large system fonts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';
import 'package:oral_collector/features/profile/presentation/widgets/profile_header.dart';

import '../../../../support/text_scale.dart';

const _longName = 'Alexandrina Wilhelmina Bartholomew-Fitzgerald the Third';

final _user = User(
  id: 'u1',
  email: 'alexandrina.wilhelmina@example.com',
  displayName: _longName,
  isPlatformAdmin: false,
  createdAt: DateTime(2024, 1, 1),
);

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: ProfileHeader(
      user: _user,
      isUploadingAvatar: false,
      colors: AppColors.light,
      theme: ThemeData.light(),
      onPickAvatar: () {},
      onEditName: () {},
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

  testWidgets('display name ellipsizes at 2.0x', (tester) async {
    await _pump(tester, 2.0);
    expect(
      tester.widget<Text>(find.text(_longName)).overflow,
      TextOverflow.ellipsis,
    );
  });
}
