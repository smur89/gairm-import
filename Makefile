# gairm-import — local build helper; CI calls these same targets.
#
# `make help` lists the targets and the variables you can override,
# from the `## ` note on each rule and `?=` default.

# A failed recipe can leave a partial target that the next `make`
# would treat as fresh. Delete it instead.
.DELETE_ON_ERROR:

TYPST    ?= typst ## the typst binary
TYPSTYLE ?= typstyle ## the typstyle binary
ROOT     := .

# Import lists group semantically (kinds, then combinators, then
# lenses), not alphabetically — keep typstyle's hands off the order.
TYPSTYLE_FLAGS := --no-reorder-import-items
TYPSTYLE_INPUT := lib.typ internal tests

TESTS         := $(wildcard tests/*.typ)
PANIC_TESTS   := $(wildcard tests/panics/*.typ)
PACKAGE_TESTS := $(wildcard tests/package/*.typ)

PACKAGE_NAME  := gairm-import
# Files that ship to typst/packages: shared by the release tarball and
# the package-check stager so the two can't drift.
PACKAGE_FILES := typst.toml lib.typ internal LICENSE README.md CONTRIBUTING.md

# Where tests/package/ compiles against the package as @preview users
# get it, at version 0.0.0 so its imports never need bumping. Gitignored.
PACKAGE_PATH  := .package-path

.PHONY: all test test-fixtures test-panics test-package stage-test-package check fmt fmt-check check-layers clean help stage-package-dir package-tarball

all: test

# One target per checked file, so `make -j` parallelises them and `-k`
# reports every failure. On GitHub Actions each check is a log group
# with an `::error file=` annotation.
#   $(call compile-one,<file>[,<extra typst flags>])
define compile-one
@if [ -n "$$GITHUB_ACTIONS" ]; then printf '::group::%s\n' "$(1)"; \
else printf '  %s\n' "$(1)"; fi; \
status=0; \
if ! $(TYPST) compile --root $(ROOT) $(2) --format pdf "$(1)" /dev/null; then \
  if [ -n "$$GITHUB_ACTIONS" ]; then printf '::error file=%s::compile failed\n' "$(1)"; fi; \
  status=1; \
fi; \
if [ -n "$$GITHUB_ACTIONS" ]; then printf '::endgroup::\n'; fi; \
exit $$status
endef

FIXTURE_CHECKS := $(addprefix check/fixture/,$(TESTS))
PANIC_CHECKS   := $(addprefix check/panic/,$(PANIC_TESTS))
PACKAGE_CHECKS := $(addprefix check/package/,$(PACKAGE_TESTS))
.PHONY: $(FIXTURE_CHECKS) $(PANIC_CHECKS) $(PACKAGE_CHECKS)

# Static pattern rules: make skips implicit rules for .PHONY targets.
$(FIXTURE_CHECKS): check/fixture/%:
	$(call compile-one,$*)

# A panic case must FAIL to compile, and its error output must contain
# the text after its leading `// expect: ` line — so a panic that stops
# firing, or fires with a different message, fails.
$(PANIC_CHECKS): check/panic/%:
	@expect=$$(sed -n '1s|^// expect: ||p' "$*"); \
	if [ -z "$$expect" ]; then \
	  printf '%s: missing leading `// expect: <message>` line\n' "$*" >&2; exit 1; \
	fi; \
	msg=; \
	if out=$$($(TYPST) compile --root $(ROOT) --format pdf "$*" /dev/null 2>&1); then \
	  msg="compiled, expected a failure containing: $$expect"; \
	elif ! printf '%s' "$$out" | grep -qF -- "$$expect"; then \
	  msg="failed without: $$expect"; \
	fi; \
	if [ -n "$$msg" ]; then \
	  printf '%s: %s\n%s\n' "$*" "$$msg" "$$out" >&2; \
	  if [ -n "$$GITHUB_ACTIONS" ]; then printf '::error file=%s::%s\n' "$*" "$$msg"; fi; \
	  exit 1; \
	fi

# Against the staged package, so a path that only resolves because the
# repo root and the package root coincide fails here (#132).
$(PACKAGE_CHECKS): check/package/%: stage-test-package
	$(call compile-one,$*,--package-path $(PACKAGE_PATH))

stage-test-package: ## stage the package as @preview users get it, for tests/package/
	@rm -rf "$(PACKAGE_PATH)"
	@$(MAKE) --no-print-directory stage-package-dir \
	  PKG_DIR="$(PACKAGE_PATH)/preview/$(PACKAGE_NAME)/0.0.0" PKG_VERSION=0.0.0

# Every check CI's test job runs, so a green `make test` locally means
# it will pass too.
test: test-fixtures test-panics test-package ## compile every fixture, check every panic case and package test

test-fixtures: $(FIXTURE_CHECKS) ## compile every tests/*.typ fixture, output discarded

test-panics: $(PANIC_CHECKS) ## check each tests/panics/*.typ fails with its `// expect:` text

test-package: $(PACKAGE_CHECKS) ## compile tests/package/*.typ against the staged package

check: test fmt-check check-layers ## test + fmt-check + check-layers: the local equivalent of CI

# internal/core/ is the bottom layer: it imports nothing outside itself.
# Any import that is not a bare sibling filename (a path leaving core/,
# or a package) is a violation.
check-layers: ## fail if internal/core/*.typ imports anything outside internal/core/
	@bad=$$(grep -nE '#import +"' internal/core/*.typ \
	  | grep -vE '#import +"[a-z][a-z0-9-]*\.typ"' || true); \
	if [ -n "$$bad" ]; then \
	  printf 'check-layers: internal/core/ may import only its own siblings:\n%s\n' "$$bad" >&2; \
	  exit 1; \
	fi

fmt: ## typstyle-format lib.typ, internal/ and tests/ in place
	$(TYPSTYLE) $(TYPSTYLE_FLAGS) -i $(TYPSTYLE_INPUT)

# Same flags as `fmt`, so CI and the local formatter agree.
fmt-check: ## check formatting without writing (the CI gate)
	$(TYPSTYLE) $(TYPSTYLE_FLAGS) --check $(TYPSTYLE_INPUT)

# Stage PACKAGE_FILES into PKG_DIR, so a missing file is caught at
# review time. PKG_VERSION, when set, is stamped into the staged
# manifest so the directory matches what @preview/<name>:<version>
# resolves to.
#
#   make stage-package-dir PKG_DIR=/tmp/.../gairm-import/0.0.0 PKG_VERSION=0.0.0
#
# `pipefail` so a failing tar producer isn't masked by the consumer's
# clean exit; invoked via bash, not .SHELLFLAGS, for Make < 3.82.
stage-package-dir: ## stage the files that ship to typst/packages (PKG_DIR=, PKG_VERSION=)
	@test -n "$(PKG_DIR)" || { echo "stage-package-dir: PKG_DIR=/path required" >&2; exit 2; }
	@mkdir -p "$(PKG_DIR)"
	@bash -eo pipefail -c 'tar cf - $(PACKAGE_FILES) | tar xf - -C "$(PKG_DIR)"'
	@if [ -n "$(PKG_VERSION)" ]; then \
	  sed 's/^version = ".*"/version = "$(PKG_VERSION)"/' typst.toml > "$(PKG_DIR)/typst.toml"; \
	fi

# Same file set, gzipped: the release asset submitted to typst/packages.
#
#   make package-tarball PACKAGE_TARBALL=$(PACKAGE_NAME)-$(VERSION).tar.gz
package-tarball: ## build the release tarball (PACKAGE_TARBALL=)
	@test -n "$(PACKAGE_TARBALL)" || { echo "package-tarball: PACKAGE_TARBALL=/path.tar.gz required" >&2; exit 2; }
	tar czf "$(PACKAGE_TARBALL)" $(PACKAGE_FILES)

clean: ## remove the staged test package
	rm -rf "$(PACKAGE_PATH)"

help: ## list these targets and the variables you can override
	@awk -F':[^=]*## ' '/^[a-zA-Z0-9_.-]+:[^=]*## /{printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo 'Overrides (make VAR=value):'
	@awk -F' *[?]= *| *## ' '/^[A-Z_]+ *[?]=.*## /{printf "  %-20s %s (default %s)\n", $$1, $$3, $$2}' $(MAKEFILE_LIST)
