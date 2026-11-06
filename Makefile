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
PACKAGE_FILES := typst.toml lib.typ internal LICENSE README.md REFERENCE.md CONTRIBUTING.md

# Where tests/package/ compiles against the package as @preview users
# get it, at version 0.0.0 so its imports never need bumping. Gitignored.
PACKAGE_PATH  := .package-path

.PHONY: all test test-fixtures test-panics test-package stage-test-package check fmt fmt-check check-layers check-conventions clean help stage-package-dir package-tarball

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

test: test-fixtures test-panics test-package ## compile every fixture, check every panic case and package test

test-fixtures: $(FIXTURE_CHECKS) ## compile every tests/*.typ fixture, output discarded

test-panics: $(PANIC_CHECKS) ## check each tests/panics/*.typ fails with its `// expect:` text

test-package: $(PACKAGE_CHECKS) ## compile tests/package/*.typ against the staged package

# Exactly what CI's `test` job runs, so a green `make check` locally
# means a green required check.
check: test fmt-check check-layers check-conventions ## test + fmt-check + check-layers + check-conventions: what CI runs

# Layer rules, bottom up, one row per layer: the files, the imports
# they may make (an extended regex), and how the error says so.
# internal/core/ (L0) imports nothing outside itself: any import that
# is not a bare sibling filename (a path leaving core/, or a package)
# is a violation. internal/kinds/ (L1) may also import from core/
# (`../core/<name>.typ`), and nothing else. internal/engine.typ (L2)
# imports only from core/ and kinds/. internal/json-schema/ (L3)
# imports from core/, kinds/, the engine and its own siblings: never
# lens, introspect or json-resume. The other L3 modules,
# internal/lens.typ and internal/introspect.typ, import only from
# core/, kinds/ and the engine: never each other. internal/json-resume/
# (L4) may import anything below it and its siblings.
SIBLING_IMPORT := \#import +"[a-z][a-z0-9-]*\.typ"
LAYERS := core kinds engine json-schema lens-introspect json-resume

core.files := internal/core/*.typ
core.allow := $(SIBLING_IMPORT)
core.says  := internal/core/ may import only its own siblings

kinds.files := internal/kinds/*.typ
kinds.allow := $(SIBLING_IMPORT)|\#import +"\.\./core/[a-z][a-z0-9-]*\.typ"
kinds.says  := internal/kinds/ may import only internal/core/ and its own siblings

engine.files := internal/engine.typ
engine.allow := \#import +"(core|kinds)/[a-z][a-z0-9-]*\.typ"
engine.says  := internal/engine.typ may import only internal/core/ and internal/kinds/

json-schema.files := internal/json-schema/*.typ
json-schema.allow := $(SIBLING_IMPORT)|\#import +"\.\./((core|kinds)/[a-z][a-z0-9-]*|engine)\.typ"
json-schema.says  := internal/json-schema/ may import only internal/core/, internal/kinds/, internal/engine.typ and its own siblings

lens-introspect.files := internal/lens.typ internal/introspect.typ
lens-introspect.allow := \#import +"((core|kinds)/[a-z][a-z0-9-]*|engine)\.typ"
lens-introspect.says  := internal/lens.typ and internal/introspect.typ may import only internal/core/, internal/kinds/ and internal/engine.typ

json-resume.files := internal/json-resume/*.typ
json-resume.allow := $(SIBLING_IMPORT)|\#import +"\.\./((core|kinds|json-schema)/[a-z][a-z0-9-]*|engine|lens|introspect)\.typ"
json-resume.says  := internal/json-resume/ may import only the layers below it and its own siblings

# One layer's check, as shell that sets `status=1` on a violation.
#   $(call check-layer,<row>)
define check-layer
bad=$$(grep -HnE '#import +"' $($(1).files) \
  | grep -vE '$($(1).allow)' || true); \
if [ -n "$$bad" ]; then \
  printf 'check-layers: %s:\n%s\n' '$($(1).says)' "$$bad" >&2; \
  status=1; \
fi;
endef

check-layers: ## fail if an internal/ module imports above its layer
	@status=0; \
	$(foreach layer,$(LAYERS),$(call check-layer,$(layer))) \
	exit $$status

# Conventions the layering rule doesn't cover. A kind's behaviour lives
# in its registry descriptor, so the engine, lenses and introspection
# test `.kind` only where that line, or the one above, carries
# `// kind-check: <why>`. Panics go
# through core/error.typ's helpers. Each panic case is named after the
# public function that panics (tests/exports.typ lists them), or
# `import-` for the checks that run when the package loads.
CONVENTION_KIND_FILES := internal/engine.typ internal/lens.typ internal/introspect.typ
PANIC_PREFIXES = import $(shell sed -nE 's/^  "([a-z0-9-]+)",$$/\1/p' tests/exports.typ)

check-conventions: ## fail on a kind test outside the registry, a bare panic, or a misnamed panic case
	@status=0; \
	bad=$$(awk '/\.kind *[!=]=/ && !/kind-check:/ && prev !~ /kind-check:/ { print FILENAME ":" FNR ": " $$0 } { prev = $$0 }' $(CONVENTION_KIND_FILES)); \
	if [ -n "$$bad" ]; then \
	  printf 'check-conventions: a kind test outside the registry (give the descriptor a field, or mark it // kind-check: <why>):\n%s\n' "$$bad" >&2; \
	  status=1; \
	fi; \
	bad=$$(grep -HnE '(^|[^a-z_-])panic\(' lib.typ $$(find internal -name '*.typ' ! -path internal/core/error.typ) \
	  | grep -vE '^[^:]+:[0-9]+: *//' || true); \
	if [ -n "$$bad" ]; then \
	  printf 'check-conventions: panic outside internal/core/error.typ (use its helpers):\n%s\n' "$$bad" >&2; \
	  status=1; \
	fi; \
	for f in tests/panics/*.typ; do \
	  b=$${f##*/}; ok=; \
	  for p in $(PANIC_PREFIXES); do case $$b in $$p-*) ok=1;; esac; done; \
	  if [ -z "$$ok" ]; then \
	    echo "check-conventions: $$f is not named <public-function>-<problem>.typ" >&2; \
	    status=1; \
	  fi; \
	done; \
	exit $$status

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
