import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';

enum RejectionReason {
  unsupportedExtension,
  emptyFile,
  missingBytes,
  unreadableContainer,
  unsupportedCodec,
  tooLarge,
}

@immutable
class RejectedFile {
  const RejectedFile({required this.name, required this.reason, this.codec});

  final String name;
  final RejectionReason reason;
  final String? codec;
}

String localizeRejectionGroup(
  AppLocalizations l10n,
  List<RejectedFile> rejects,
) {
  final names = rejects.take(5).map((r) => r.name).join(', ');
  final suffix = rejects.length > 5 ? '…' : '';
  final joined = '$names$suffix';
  final count = rejects.length;

  final allReason = rejects.every((r) => r.reason == rejects.first.reason)
      ? rejects.first.reason
      : null;

  switch (allReason) {
    case RejectionReason.tooLarge:
      return l10n.import_rejectedTooLarge(count, joined);
    case RejectionReason.unsupportedCodec:
      return l10n.import_rejectedUnsupportedCodec(count, joined);
    case RejectionReason.unreadableContainer:
    case RejectionReason.missingBytes:
      return l10n.import_rejectedUnreadable(count, joined);
    case RejectionReason.emptyFile:
    case RejectionReason.unsupportedExtension:
    case null:
      return l10n.import_rejectedFiles(count, joined);
  }
}
