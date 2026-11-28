import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/context_tokens.dart';

const double _width = 340;
const double _gap = 10;

Future<T?> showAppQuestion<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<Widget> Function(BuildContext) actionsBuilder,
  bool isDismissible = true,
}) => showAppDialog<T>(
  context: context,
  isDismissible: isDismissible,
  builder: (c) => _card(c, title, message, actionsBuilder),
);

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    _AppQuestionRoute<T>(
      builder: builder,
      motion: context.motion,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isDismissible: isDismissible,
    ),
  );
}

class _AppQuestionRoute<T> extends PopupRoute<T> {
  _AppQuestionRoute({
    required this.builder,
    required this.motion,
    required this.themes,
    required this.barrierLabel,
    required this.isDismissible,
  });

  final WidgetBuilder builder;
  final AppMotion motion;
  final CapturedThemes themes;
  final bool isDismissible;
  bool? _entering;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Duration get transitionDuration => motion.base;

  @override
  Duration get reverseTransitionDuration => motion.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(
      Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: switch (Theme.of(context).platform) {
          TargetPlatform.iOS || TargetPlatform.macOS => '',
          _ => MaterialLocalizations.of(context).dialogLabel,
        },
        explicitChildNodes: true,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            _entering = animation.isAnimating
                ? _entering ?? animation.status == AnimationStatus.forward
                : null;
            final bool entering = _entering ?? true;
            final double v = (entering ? motion.enter : motion.leave.flipped)
                .transform(animation.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: v,
                    child: const ColoredBox(color: MotionScale.scrim),
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s16,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, entering ? motion.rise * (1 - v) : 0),
                        child: builder(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _card(
  BuildContext context,
  String title,
  String message,
  List<Widget> Function(BuildContext) actionsBuilder,
) {
  final AppColorSet colors = AppColors.of(context);
  final TextTheme text = Theme.of(context).textTheme;
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _width),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RadiusScale.r24),
        boxShadow: QuestionShadows.of(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.headlineLarge?.copyWith(fontSize: 30)),
              const SizedBox(height: _gap),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: _gap * 2),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: _gap,
                runSpacing: _gap,
                children: actionsBuilder(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
