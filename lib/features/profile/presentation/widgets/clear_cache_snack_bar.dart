import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';

/// Reports the [outcome] of a cache clear, naming the recordings that stayed on
/// the device and why each of them did.
///
/// Announcing plain success after keeping recordings would read as a defect —
/// the user asked for space back and got less than they expected — and it would
/// hide that audio the server never received is still waiting here (ENG-407).
///
/// Takes the messenger and [l10n] rather than a `BuildContext` because the
/// caller resolves both before awaiting the clear, and the context it holds is a
/// parameter no `mounted` check can vouch for.
void showClearCacheResultSnackBar(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  ClearCacheOutcome outcome,
) {
  messenger.showSnackBar(SnackBar(content: Text(_sentenceFor(l10n, outcome))));
}

/// A delete that failed costs the sentence its opening claim: "Local cache
/// cleared" next to "that space was not freed" contradicts itself, and when
/// every file refused to go it is simply false (ENG-417). Both success
/// sentences therefore stay exactly as they were, and the failure path builds
/// its own from a clause that makes no claim about the clear.
String _sentenceFor(AppLocalizations l10n, ClearCacheOutcome outcome) {
  if (outcome.keptUndeletable == 0) {
    return outcome.keptUnsent == 0
        ? l10n.profile_cacheCleared
        : l10n.profile_cacheClearedKept(outcome.keptUnsent);
  }
  final notFreed = l10n.profile_cacheNotFreed(outcome.keptUndeletable);
  if (outcome.keptUnsent == 0) return notFreed;
  return '${l10n.profile_cacheKeptUnsent(outcome.keptUnsent)} $notFreed';
}
