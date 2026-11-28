import 'package:analyzer/dart/ast/ast.dart' show SimpleIdentifier;
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'dialog_path.dart';

class AvoidRawDialog extends DartLintRule {
  const AvoidRawDialog() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_raw_dialog',
    problemMessage:
        'Raw dialog or bottom sheet. Open questions through showAppQuestion or '
        'showAppDialog (lib/shared/widgets/app_question.dart) and sheets '
        'through showAppSheet (lib/shared/widgets/app_sheet.dart).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _banned = {
    'showDialog',
    'showGeneralDialog',
    'showModalBottomSheet',
    'showBottomSheet',
  };

  static bool _isFlutterBanned(SimpleIdentifier name) {
    if (!_banned.contains(name.name)) return false;
    final library = name.staticElement?.library?.source.uri;
    return library != null &&
        library.isScheme('package') &&
        library.pathSegments.first == 'flutter';
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (isRawDialogExempt(resolver.path)) return;
    context.registry.addMethodInvocation((node) {
      if (_isFlutterBanned(node.methodName)) reporter.atNode(node, _code);
    });
  }
}
