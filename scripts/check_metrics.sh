#!/usr/bin/env sh
# Quality gate: fail if dart_code_linter reports any metric violation
# (WARNING/ALARM) against the thresholds in analysis_options.yaml.
#
# dart_code_linter 3.x always exits 0 (even with --fatal-warnings), so we
# inspect its console output and fail when a violation line is present.
# See obt/.claude/quality-gates-plan.md.
set -eu

out=$(dart run dart_code_linter:metrics analyze lib --reporter=console 2>/dev/null | tr -d '\r')
printf '%s\n' "$out"

if printf '%s\n' "$out" | grep -qE '^(WARNING|ALARM)'; then
  echo "" >&2
  echo "Metric violation(s) above the configured thresholds (see above)." >&2
  exit 1
fi

echo "dart_code_linter: no metric violations."
