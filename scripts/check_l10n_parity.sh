#!/usr/bin/env sh
# Quality gate (ENG-524): fail if a locale carries a value identical to the
# English template without being on the accepted-coincidence list in
# tool/check_l10n_parity.dart.
set -eu

# Which `dart`, because the wrong one leaves damage behind that outlives this
# script — same reasoning as scripts/check_metrics.sh: locally the SDK is
# pinned by FVM and a bare `dart` is FVM's `stable` channel, which downgrades
# the packages the Flutter SDK pins in pubspec.lock. CI has no FVM and its bare
# `dart` is already the pinned one, so it falls through.
if [ -d .fvm ] && command -v fvm >/dev/null 2>&1; then
  dart="fvm dart"
else
  dart="dart"
fi

# Unquoted on purpose: $dart is a command plus its optional prefix word.
# shellcheck disable=SC2086
$dart run tool/check_l10n_parity.dart
