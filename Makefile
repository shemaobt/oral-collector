# Local quality gates (see obt/.claude/quality-gates-plan.md).
# `make quality` = hard gates (format + analyze + code metrics).
# Coverage and cycles are advisory (report only) — see ADR-0009.
.PHONY: quality metrics coverage cycles

## quality: hard gates — formatting, analyzer, dart_code_linter metrics
quality:
	dart format --set-exit-if-changed lib/ test/
	flutter analyze --no-fatal-infos
	sh scripts/check_metrics.sh

## metrics: code metrics gate only (complexity / size / nesting / parameters)
metrics:
	sh scripts/check_metrics.sh

## coverage: run tests with coverage (advisory) -> coverage/lcov.info
coverage:
	flutter test --coverage

## cycles: import-cycle report (advisory, never blocks) -> layerlens
cycles:
	dart pub global run layerlens --fail-on-cycles || true
