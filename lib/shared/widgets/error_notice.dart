import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../utils/error_helpers.dart';
import 'quick_notice.dart';

void showErrorNotice(
  BuildContext context,
  Object rawError, {
  String Function(String friendlyError)? template,
}) {
  final friendly = friendlyErrorFor(rawError, AppLocalizations.of(context));
  showQuickNotice(
    context,
    template?.call(friendly) ?? friendly,
    tone: QuickNoticeTone.failed,
  );
}
