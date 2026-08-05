import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

/// A realistic phone viewport. Deliberately NOT a huge viewport: text-scale
/// regressions only surface when content has to fit a real screen.
const Size kPhoneSize = Size(390, 844);

/// Pumps [child] inside a localized [MaterialApp] with the system text scale
/// forced to [scale]. Use this to assert layouts survive large fonts.
///
/// The [MediaQuery] override sits below [MaterialApp] because MaterialApp
/// otherwise resets the text scaler to the platform default.
Future<void> pumpAtTextScale(
  WidgetTester tester, {
  required Widget child,
  double scale = 1.0,
  List<Override> overrides = const [],
  Size size = kPhoneSize,
  double devicePixelRatio = 3.0,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Fails if a RenderFlex/RenderBox overflow (or any other error) was thrown
/// during the most recent layout. Overflow surfaces as a takeable exception.
void expectNoOverflow(WidgetTester tester) =>
    expect(tester.takeException(), isNull);
