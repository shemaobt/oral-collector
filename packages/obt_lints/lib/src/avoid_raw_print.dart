import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'observability_path.dart';

class AvoidRawPrint extends DartLintRule {
  const AvoidRawPrint() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_raw_print',
    problemMessage:
        'Raw print/debugPrint. Route console output through the logging '
        'facade (package:logging Logger; see lib/core/observability, ADR-0010).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static bool _isBanned(String name) => name == 'print' || name == 'debugPrint';

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isRawPrintExempt(resolver.path)) return;
    // `print` é função top-level → MethodInvocation. `debugPrint` é uma variável
    // top-level (reatribuível) → o resolver reescreve a chamada como
    // FunctionExpressionInvocation. Cobrimos os dois nós (ambos sem receptor).
    context.registry.addMethodInvocation((node) {
      if (node.target != null) return;
      if (_isBanned(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
    context.registry.addFunctionExpressionInvocation((node) {
      final function = node.function;
      if (function is SimpleIdentifier && _isBanned(function.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
