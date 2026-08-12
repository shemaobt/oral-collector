#!/usr/bin/env sh
# Quality gate: fail if dart_code_linter reports any metric violation
# (WARNING/ALARM) against the thresholds in analysis_options.yaml.
#
# dart_code_linter 3.x always exits 0 (even with --fatal-warnings), so we
# inspect its console output and fail when a violation line is present.
# See obt/.claude/quality-gates-plan.md.
set -eu

# Which `dart`, because the wrong one leaves damage behind that outlives this
# script. Locally the SDK is pinned by FVM and a bare `dart` is FVM's `stable`
# channel instead: it downgrades the packages the Flutter SDK pins in
# pubspec.lock (characters, matcher, material_color_utilities, test_api), and
# the downgraded `matcher` then breaks compilation inside a test run already in
# flight — which reads as a bug in `semantics.dart` and is not one. CI has no
# FVM and its bare `dart` is already the pinned one, so it falls through.
# Both conditions: `fvm` without this project's .fvm/ is someone else's pin.
if [ -d .fvm ] && command -v fvm >/dev/null 2>&1; then
  dart="fvm dart"
else
  dart="dart"
fi

# Unquoted on purpose: $dart is a command plus its optional prefix word.
# shellcheck disable=SC2086
out=$($dart run dart_code_linter:metrics analyze lib --reporter=console 2>/dev/null | tr -d '\r')
printf '%s\n' "$out"

if printf '%s\n' "$out" | grep -qE '^(WARNING|ALARM)'; then
  echo "" >&2
  echo "Metric violation(s) above the configured thresholds (see above)." >&2
  exit 1
fi

echo "dart_code_linter: no metric violations."
