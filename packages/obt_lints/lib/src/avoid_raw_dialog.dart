import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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

  static bool _isExempt(String path) {
    final normalized = path.replaceAll(r'\', '/');
    return !normalized.contains('/lib/') ||
        normalized.endsWith('/lib/shared/widgets/app_question.dart');
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (_isExempt(resolver.path)) return;
    context.registry.addMethodInvocation((node) {
      if (node.target == null && _banned.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
