import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'dialog_path.dart';

class AvoidRawDialog extends DartLintRule {
  const AvoidRawDialog() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_raw_dialog',
    problemMessage:
        'Raw showDialog/showGeneralDialog. Open questions through '
        'showAppQuestion or showAppDialog (lib/shared/widgets/app_question.dart).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _banned = {'showDialog', 'showGeneralDialog'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isRawDialogExempt(resolver.path)) return;
    context.registry.addMethodInvocation((node) {
      if (node.target == null && _banned.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
