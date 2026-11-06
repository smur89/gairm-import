# Architecture

How gairm-import is put together, for contributors. For usage, see the
[README](README.md) and [REFERENCE.md](REFERENCE.md).

The package does one thing: walk a value against a schema and report
what doesn't match, optionally returning a cleaned-up model of the value.
Everything else (the JSON Schema translator, lenses, introspection) is
built on the same schema representation and the same walk.

## Codemap

```text
lib.typ                     # the only public surface
internal/core/              # L0: input forms, errors, the walk context, JSON Pointer
internal/kinds/             # L1: constructors, formats, constraint rows, the kind registry, traversal
internal/engine.typ         # L2: the one walk over schema and value
internal/json-schema/       # L3: the JSON Schema translator
internal/lens.typ           # L3: lens-get / lens-put / lens-over and the field edits
internal/introspect.typ     # L3: describe-schema, paths-of-kind
internal/json-resume/       # L4: the bundled JSON Resume schemas (deprecated, #200)
tests/*.typ                 # assertions, one file per public concept
tests/panics/               # one case per place the package panics
tests/package/              # compiled against the staged package; readme-* and reference-* mirror the docs
```

A module imports only from layers below it and its own siblings. The L3
modules outside `json-schema/` import only from core, kinds and the
engine, never each other. `make check-layers` enforces this from one rule
table in the Makefile. `lib.typ` reaches internals through underscore
aliases, so a name that starts with `_` is never part of the API, and
`tests/exports.typ` pins the export list.

## Schemas are data

A schema is a plain dictionary tagged with a `kind`:
`(kind: "string", min-length: 3)`, `(kind: "object", shape: (..),
required-keys: (..))`, `(kind: "union", members: (..), exclusive: false)`.
Constructors (`string()`, `object()`, `any-of()`, `if-of()`, …) only build
and check these dictionaries; nothing about a kind's behaviour lives in
the node. Because nodes are data, they compare with `==`, print with
`repr`, and can be edited (lenses) or translated into (JSON Schema).

Constraints and formats are fields, not kinds: a dated string with a
pattern is `(kind: "string", format: "date", pattern: …)`.

## The kind registry

`internal/kinds/registry.typ` holds one descriptor per kind. It is the
single place a kind's behaviour is defined; the engine, lenses and
introspection read it and never branch on `kind` themselves.

| Field | Used by | Meaning |
|---|---|---|
| `walk` (or `check` + `family` + `model` for leaves) | engine | how a value is judged and modelled |
| `children` | lens, introspection, traversal | `(segment, node, label)` per child |
| `with-child` | lens, traversal | the node with one child replaced |
| `bad-segment` | lens | the message for a segment the kind doesn't have |
| `suffix`, `inline`, `shorthand` | `describe-schema` | how the node draws |
| `searchable` | `paths-of-kind` | whether the kind can be searched for |
| `constructors` | load-time check | the exported functions that build it |

At load, the registry checks that every exported constructor and constant
belongs to some descriptor, so a new kind can't be half-registered.
Deprecated kind names (`"str"`, `"date-string"`, …) map to nodes through
`_kind-aliases` / `_node` in `structure.typ`, applied at the few points
that read a kind.

## The walk

`internal/engine.typ` has one function:

```text
_walk(schema, value, ctx) -> (errors, value, fatal)
```

- `errors`: every validation error, in walk order. A record is
  `(path, code, message, expected, got)`; `code` is one of the fixed set
  in `core/error.typ` (an unknown code is an internal error).
- `value`: the model, with absent and unknown keys dropped and each leaf
  through its kind's `model` (a `content-type` string becomes markup;
  formatted strings stay strings).
- `fatal`: `none`, or the first place where no sound model exists,
  which is what `coerce` panics with.

`validate`, `coerce` and `parse` are thin views over one walk, so they
cannot disagree. `ctx` (`core/ctx.typ`) carries the data path and the
options (only `strict-null` today); absence of a null is decided there
and nowhere else. Composite kinds recurse through the `recur` argument
their `walk` receives, never by importing the engine.

## The translator

`internal/json-schema/` turns a draft-7 subset into the same nodes.

- `keyword.typ`: the keyword table. Each keyword has a role:
  `annotation`, `type`, `base` (per JSON type), `constraint` (derived
  from the constraint rows), `membership` (`enum` / `const`),
  `applicator` (`allOf` / `anyOf` / `oneOf` / `not` / `if`), `branch`
  (`then` / `else`), `ref`, or `unsupported` with a reason. The
  allow-list, the "unsupported keyword" panic and the stand-alone rules
  all read this table.
- `translate.typ`: the entry point, `$ref` resolution and the dispatcher.
- `build.typ`: one builder per JSON type, plus the `enum` / `const` fold.
- `all-of.typ` and `conditional.typ`: `allOf`, and `if` / `then` /
  `else` beside other keywords, are merged into object nodes at translate
  time; the engine has no general intersection kind.

Anything the translator can't honour panics with the keyword's name
rather than dropping the constraint.

## Invariants and constraints

- **Failure is `panic`.** Typst has no try/catch. Validation errors are
  returned as data; only the entry points (`coerce`, `parse`) and bad
  arguments panic, always prefixed `gairm-import:`.
- **One source of truth per rule.** A constraint is one row in
  `kinds/constraint.typ`: it drives the constructor argument, the JSON
  keyword, the check, the error code and the "bounds can't both hold"
  check. Formats are rows in `kinds/format.typ`.
- **Call depth.** Typst stops at about 80 nested calls. Each level of
  nesting costs a fixed number of frames, and `tests/engine-walk.typ` pins
  how deep a document may go; a change that adds frames per level shows
  up there.
- **Functions compare by identity**, which is why constructors and
  constants can be compared and listed in descriptors.
- **No runtime dependencies**, and nothing is loaded lazily: everything a
  module defines at top level is evaluated on import.

## Where to change things

- **A constraint** (e.g. a new `maxContains`-style bound): add a row to
  `kinds/constraint.typ`, an argument to the family's constructor
  (`tests/constraint-rows.typ` fails until you do), and a REFERENCE.md
  line.
- **A format**: add a row to `kinds/format.typ`.
- **A kind**: a constructor in `kinds/`, a descriptor in `registry.typ`,
  an export in `lib.typ` and `tests/exports.typ`, and a row in the
  describe/lens tables of REFERENCE.md.
- **A JSON Schema keyword**: an entry in `json-schema/keyword.typ`, then
  the builder or applicator that consumes it.
- **A panic**: word it through the helpers in `core/error.typ`, and add
  one case in `tests/panics/` named `<public-function>-<problem>.typ`.

Deprecations and the 1.0 removals are tracked on
[#186](https://github.com/smur89/gairm-import/issues/186).
