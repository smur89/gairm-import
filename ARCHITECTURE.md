# Architecture

How gairm-import is put together, for contributors. For usage, see the
[README](README.md) and [REFERENCE.md](REFERENCE.md). This is a map: each
module's header comment is the detailed, authoritative description, and
this file says which header to read.

The package walks a value against a schema and reports what doesn't
match, optionally returning a cleaned-up model of the value. The JSON
Schema translator, lenses and introspection are built on the same schema
representation and the same walk.

## Codemap

```text
lib.typ                     # the only public surface
internal/core/              # L0: input forms, errors, the walk context, JSON Pointer
internal/kinds/             # L1: constructors, formats, constraint rows, the kind registry, traversal
internal/engine.typ         # L2: the one walk over schema and value
internal/json-schema/       # L3: the JSON Schema translator
internal/lens.typ           # L3: lens-get / lens-put / lens-over and the field edits
internal/introspect.typ     # L3: describe-schema, paths-of-kind
internal/json-resume/       # L4: the bundled JSON Resume schemas (deprecated)
tests/*.typ                 # assertions, one file per public concept
tests/panics/               # one case per place the package panics
tests/package/              # compiled against the staged package; readme-* and reference-* mirror the docs
```

`make check-layers` enforces the layering; the rule table in the Makefile
is authoritative. `lib.typ` reaches internals through underscore aliases,
so a name that starts with `_` is never part of the API, and
`tests/exports.typ` pins what is.

## Schemas are data

A schema is a plain dictionary tagged with a `kind`:
`(kind: "string", min-length: 3)`, `(kind: "union", members: (..),
exclusive: false)`. Constructors only build and check these dictionaries;
constraints and formats are fields, not kinds. Because nodes are data,
they compare with `==`, print with `repr`, and can be edited (lenses) or
produced by the translator.

A kind's behaviour lives in its descriptor in `kinds/registry.typ` (the
header lists the fields): how it walks, its children and their labels,
how a lens replaces a child, and how `describe-schema` draws it. The
engine, lenses and introspection read the registry rather than keeping
their own `kind ==` ladders; `make check-conventions` rejects a test
for a named kind outside `internal/kinds/` unless it is marked
`// kind-check: <why>`.

## The walk

`engine.typ`'s `_walk(schema, value, ctx) -> (errors, value, fatal)` is
the only walk; `validate`, `coerce` and `parse` are views over one result,
so they can't disagree. Its header explains the three parts, and
`core/ctx.typ`'s explains the context and how null counts as absent.
Composite kinds recurse through the `recur` argument their `walk`
receives.

## The translator

`internal/json-schema/` turns a draft-7 subset into the same nodes.
`keyword.typ`'s table gives each keyword a role, and the allow-list, the
"unsupported keyword" panic and the stand-alone rules read it.
`translate.typ` dispatches, `build.typ` has one builder per JSON type,
and `all-of.typ` / `conditional.typ` merge `allOf`, and `if` / `then` /
`else` beside other keywords, into object nodes at translate time: the
engine has no general intersection kind.

## Constraints that shape the code

- **Failure is `panic`.** Typst has no try/catch, so validation errors
  are returned as data and only the entry points and bad arguments panic.
- **One row per rule.** A constraint is a row in `kinds/constraint.typ`
  and a format a row in `kinds/format.typ`; their headers list everything
  that reads a row.
- **Call depth.** Typst stops at about 80 nested calls, and
  `tests/engine-walk.typ` pins how deep a document may nest.
- **No runtime dependencies**, and every module's top level is evaluated
  on import.

## Where to change things

- **A constraint**: a row in `kinds/constraint.typ` and an argument on the
  family's constructor (`tests/constraint-rows.typ` fails until it
  exists), plus REFERENCE.md.
- **A format**: a row in `kinds/format.typ`, plus REFERENCE.md.
- **A kind**: a constructor in `kinds/`, a descriptor in `registry.typ`
  (a load-time check fails on an exported constructor no descriptor
  lists), and an export in `lib.typ` and `tests/exports.typ`, plus
  REFERENCE.md.
- **A JSON Schema keyword**: an entry in `json-schema/keyword.typ`, then
  the builder or applicator that consumes it.
- **A panic**: the helpers in `core/error.typ`, and a case in
  `tests/panics/` (see [CONTRIBUTING.md](CONTRIBUTING.md)).
