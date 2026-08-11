import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Reports the outcome of a cache clear, naming the [keptCount] recordings that
/// stayed on the device.
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
  int keptCount,
) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        keptCount == 0
            ? l10n.profile_cacheCleared
            : l10n.profile_cacheClearedKept(keptCount),
      ),
    ),
  );
}
