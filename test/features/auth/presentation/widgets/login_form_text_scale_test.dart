// ENG-181: the login form footer ("no account?" prompt + sign-up action) must
// survive large system fonts without overflowing horizontally. Rendered on a
// realistic phone viewport via pumpAtTextScale; the form itself scrolls.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/auth/presentation/widgets/login_form.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  final email = TextEditingController();
  final password = TextEditingController();
  addTearDown(email.dispose);
  addTearDown(password.dispose);
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: SingleChildScrollView(
      child: Builder(
        builder: (context) => LoginForm(
          emailController: email,
          passwordController: password,
          obscurePassword: true,
          onToggleObscure: () {},
          onLogin: () {},
          isLoading: false,
          colors: AppColors.light,
          theme: Theme.of(context),
          onGoToSignup: () {},
          onForgotPassword: () {},
        ),
      ),
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

  testWidgets('sign-up affordance stays in the tree at 2.0x', (tester) async {
    await _pump(tester, 2.0);
    expect(find.text(AppLocalizationsEn().auth_signUp), findsOneWidget);
  });
}
