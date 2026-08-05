import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'theme_path.dart';

class AvoidMaterialColors extends DartLintRule {
  const AvoidMaterialColors() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_material_colors',
    problemMessage:
        'Bare Colors.* (Material palette). Use a color token from '
        'lib/core/theme (AppColors / AppColorSet) instead.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isColorLintExempt(resolver.path)) return;
    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name != 'Colors') return; // ignora AppColors etc.
      reporter.atNode(node, _code);
    });
  }
}
