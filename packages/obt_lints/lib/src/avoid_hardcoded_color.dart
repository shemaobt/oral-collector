import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'theme_path.dart';

const _colorChecker = TypeChecker.fromUrl('dart:ui#Color');

class AvoidHardcodedColor extends DartLintRule {
  const AvoidHardcodedColor() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_color',
    problemMessage:
        'Hardcoded Color constructor. Use a color token from '
        'lib/core/theme (AppColors / AppColorSet) instead.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isThemeFile(resolver.path)) return;
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type == null) return;
      // isExactlyType pega Color e seus ctors nomeados (fromARGB/fromRGBO/from);
      // subclasses (MaterialColor) não são "exatas" e ficam para a outra regra.
      if (_colorChecker.isExactlyType(type)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
