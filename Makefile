# gairm-import — local build helper. Mirrors the compile sweep CI runs
# on every PR.
#
# Usage:
#   make             # compile every tests/*.typ fixture (output discarded)
#   make test        # alias for the default target
#   make check       # alias for `make test` — matches the CI lint name
#   make fmt         # typstyle-format lib.typ, internal/, tests/ in place
#   make fmt-check   # exit non-zero if any file needs formatting (CI advisory job)
#   make clean       # no-op today — tests compile to /dev/null, nothing to remove
#   make help        # summarise the available targets
#
# Tool overrides:
#   make TYPST=/path/to/typst          # use a non-default typst binary
#   make TYPSTYLE=/path/to/typstyle    # use a non-default typstyle binary

# Delete the target of any recipe that exits non-zero so a partially-
# written file does not look fresh to a subsequent `make` invocation.
.DELETE_ON_ERROR:

TYPST    ?= typst
TYPSTYLE ?= typstyle
ROOT     := .

# Import lists group semantically (kinds, then combinators, then
# lenses), not alphabetically — keep typstyle's hands off the order.
TYPSTYLE_FLAGS := --no-reorder-import-items
TYPSTYLE_INPUT := lib.typ internal tests

TESTS := $(wildcard tests/*.typ)

# Files that ship to typst/packages. Single source of truth for the
# release tarball recipe AND the PR-time package-check stager — pulling
# the list here keeps the two from drifting (the same drift that
# slipped CONTRIBUTING.md past altacv 1.4.1's typst-package-check).
PACKAGE_FILES := typst.toml lib.typ internal LICENSE README.md CONTRIBUTING.md

.PHONY: all test check fmt fmt-check clean help stage-package-dir package-tarball

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

fmt:
	$(TYPSTYLE) $(TYPSTYLE_FLAGS) -i $(TYPSTYLE_INPUT)

# Same flags as `fmt` so the CI advisory job and the local formatter
# can never disagree about what "formatted" means.
fmt-check:
	$(TYPSTYLE) $(TYPSTYLE_FLAGS) --check $(TYPSTYLE_INPUT)

# Stage every file that ships to typst/packages into PKG_DIR. Used by
# the CI package-check job (PR-time) to lay out the same file set the
# release tarball would publish — typst-package-check then validates
# THAT directory, so a missing file is caught at review time.
#
#   make stage-package-dir PKG_DIR=/tmp/.../gairm-import/0.0.0
#
# `bash -eo pipefail` so a missing file makes the tar producer fail
# the recipe — without pipefail the consumer's clean exit would
# silently mask a partial stage. Invoked explicitly (not via
# .SHELLFLAGS) so this works on Make < 3.82.
stage-package-dir:
	@test -n "$(PKG_DIR)" || { echo "stage-package-dir: PKG_DIR=/path required" >&2; exit 2; }
	@mkdir -p "$(PKG_DIR)"
	@bash -eo pipefail -c 'tar cf - $(PACKAGE_FILES) | tar xf - -C "$(PKG_DIR)"'

# Same file set, gzipped — the artifact attached to the GitHub Release
# and uploaded to typst/packages.
#
#   make package-tarball PACKAGE_TARBALL=$(PACKAGE_NAME)-$(VERSION).tar.gz
package-tarball:
	@test -n "$(PACKAGE_TARBALL)" || { echo "package-tarball: PACKAGE_TARBALL=/path.tar.gz required" >&2; exit 2; }
	tar czf "$(PACKAGE_TARBALL)" $(PACKAGE_FILES)

clean:
	@:

help:
	@printf '%s\n' 'Targets: all (default) | test (alias: check) | fmt | fmt-check | clean' \
	  'Per-target detail: see the header comment in this Makefile.' \
	  'Overrides: TYPST=path/to/typst | TYPSTYLE=path/to/typstyle'
