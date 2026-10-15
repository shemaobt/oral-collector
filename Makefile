# Local quality gates (see obt/.claude/quality-gates-plan.md).
# `make quality` = hard gates (format + analyze + code metrics + l10n parity).
# Coverage and cycles are advisory (report only) — see ADR-0009.
.PHONY: quality metrics l10n coverage cycles

## quality: hard gates — formatting, analyzer, dart_code_linter metrics, l10n parity
quality:
	dart format --set-exit-if-changed lib/ test/
	flutter analyze --no-fatal-infos
	sh scripts/check_metrics.sh
	sh scripts/check_l10n_parity.sh

## l10n: translation parity gate only (ENG-524)
l10n:
	sh scripts/check_l10n_parity.sh

## metrics: code metrics gate only (complexity / size / nesting / parameters)
metrics:
	sh scripts/check_metrics.sh

## coverage: run tests with coverage (advisory) -> coverage/lcov.info
coverage:
	flutter test --coverage

## cycles: import-cycle report (advisory, never blocks) -> layerlens
cycles:
	dart pub global run layerlens --fail-on-cycles || true
