.PHONY: help get bootstrap gen gen-watch format analyze test

help:
	@echo "Available commands:"
	@printf "%-25s %s\n" "make get" "Get workspace dependencies"
	@printf "%-25s %s\n" "make bootstrap" "Get dependencies and run codegen in every package"
	@printf "%-25s %s\n" "make gen" "Run codegen in every package"
	@printf "%-25s %s\n" "make format" "Format all packages"
	@printf "%-25s %s\n" "make analyze" "Analyze workspace"
	@printf "%-25s %s\n" "make test" "Run all tests"

get:
	fvm flutter pub get

bootstrap:
	bash scripts/bootstrap.bash

gen:
	bash scripts/codegen.bash build

gen-watch:
	bash scripts/codegen.bash watch

format:
	bash scripts/format.bash

analyze:
	bash scripts/analyze.bash

test:
	bash scripts/test.bash
