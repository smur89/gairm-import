# json-resume — local build helper. Mirrors the compile sweep CI runs
# on every PR.
#
# Usage:
#   make             # compile every tests/*.typ fixture (output discarded)
#   make test        # alias for the default target
#   make check       # alias for `make test` — matches the CI lint name
#   make clean       # remove any generated artifacts
#   make help        # summarise the available targets
#
# Tool overrides:
#   make TYPST=/path/to/typst    # use a non-default typst binary

# Delete the target of any recipe that exits non-zero so a partially-
# written file does not look fresh to a subsequent `make` invocation.
.DELETE_ON_ERROR:

TYPST ?= typst
ROOT  := .

TESTS := $(wildcard tests/*.typ)

.PHONY: all test check clean help

all: test

# Compile every fixture; output goes to /dev/null. Same shape as the
# CI lint job, so a green `make test` locally means the CI lint step
# will also pass. When `GITHUB_ACTIONS` is set, the recipe also emits
# `::group::` / `::endgroup::` markers for collapsible per-file log
# sections and `::error file=<path>::` annotations for failing files.
test:
	@status=0; \
	for f in $(TESTS); do \
	  if [ -n "$$GITHUB_ACTIONS" ]; then printf '::group::%s\n' "$$f"; \
	  else printf '  %s\n' "$$f"; fi; \
	  if ! $(TYPST) compile --root $(ROOT) --format pdf "$$f" /dev/null; then \
	    if [ -n "$$GITHUB_ACTIONS" ]; then \
	      printf '::error file=%s::compile failed\n' "$$f"; \
	    fi; \
	    status=1; \
	  fi; \
	  if [ -n "$$GITHUB_ACTIONS" ]; then printf '::endgroup::\n'; fi; \
	done; \
	exit $$status

check: test

clean:
	@:

help:
	@printf '%s\n' 'Targets: all (default) | test (alias: check) | clean' \
	  'Per-target detail: see the header comment in this Makefile.' \
	  'Overrides: TYPST=path/to/typst'
