// One descriptor per schema kind, so the engine, lens, introspection
// and the strict-schema walkers ask the registry instead of keeping
// their own `kind ==` ladders. A descriptor holds:
//
//   leaf          no children: traversal stops here
//   searchable    paths-of-kind finds it, rather than only walking
//                 through it
//   children      schema => ((segment, sub-schema), ..), segments as lens
//                 paths spell them
//   with-child    (schema, segment, sub) => the node with that child
//                 replaced
//   suffix        schema => what describe-schema prints on the node's own
//                 row: a leaf's kind, a union's header, none for no
//                 header
//   labels        schema => describe-schema's label for each child, in
//                 children order
//   shorthand     schema => none, or (of, mark): describe-schema draws
//                 the node as `of` with `mark` (a nullable as `X?`)
//   bad-segment   (schema, segment) => what a lens says when the segment
//                 names no child
//   constructors  the public functions that build this kind
//
// and the engine's fields, either the leaf trio
//
//   check         (schema, value, ctx) => (errors, value, fatal): judges
//                 the JSON-level value, may normalise it, and says
//                 whether it leaves a model (leaf.typ)
//   model         value => the model value, when the check left one
//   family        which constraint rows the engine applies after the
//                 check passes (none: no rows)
//
// or, for kinds that contain other schemas,
//
//   walk          (schema, value, ctx, recur) => (errors, value, fatal)
//                 (structure.typ)

#import "leaf.typ" as _leaf-mod
#import "leaf.typ": (
  pattern-string, enum-of, const-of, _string-check, _number-check, _bool-check,
  _null-check, _any-check, _pattern-check, _enum-check,
)
#import "format.typ" as _format-mod
#import "format.typ": _formats, _format-check
#import "structure.typ" as _structure-mod
#import "structure.typ": (
  array-of, object, map, any-of, one-of, not-of, nullable, _array-walk,
  _object-walk, _union-walk, _not-walk, _object-with, _schema-kinds,
)

#let _kind(
  leaf: true,
  searchable: true,
  children: s => (),
  with-child: none,
  suffix: s => s.kind,
  labels: s => (),
  shorthand: s => none,
  bad-segment: (s, seg) => (
    "lens cannot descend into a leaf schema (kind="
      + repr(s.kind)
      + ") with segment "
      + repr(seg)
      + "."
  ),
  constructors: (),
  family: none,
  check: none,
  model: v => v,
  walk: none,
) = (
  leaf: leaf,
  searchable: searchable,
  children: children,
  with-child: with-child,
  suffix: suffix,
  labels: labels,
  shorthand: shorthand,
  bad-segment: bad-segment,
  constructors: constructors,
  family: family,
  check: check,
  model: model,
  walk: walk,
)

// A format kind with an extra pattern gate (JSON Schema format +
// pattern) says so.
#let _format-kind(row) = _kind(
  check: _format-check(row),
  family: "string",
  suffix: s => if "pattern" in s { s.kind + " + pattern" } else { s.kind },
)

#let _kinds = (
  str: _kind(check: _string-check, family: "string"),
  // The model wraps the string so it splices into markup.
  content: _kind(check: _string-check, family: "string", model: v => [#v]),
  number: _kind(check: _number-check, family: "number"),
  bool: _kind(check: _bool-check),
  null: _kind(check: _null-check),
  any: _kind(check: _any-check),
  .._formats.values().map(row => (row.kind, _format-kind(row))).to-dict(),
  pattern-string: _kind(
    check: _pattern-check,
    family: "string",
    constructors: (pattern-string,),
  ),
  // The values inline, for at-a-glance debugging.
  enum: _kind(
    check: _enum-check,
    suffix: s => "enum (" + s.values.map(repr).join(", ") + ")",
    constructors: (enum-of, const-of),
  ),
  // paths-of-kind only walks through the two plain containers: every
  // schema is full of them, so asking for one is more likely a slip
  // than a question.
  array: _kind(
    walk: _array-walk,
    leaf: false,
    searchable: false,
    children: s => (("items", s.elem),),
    with-child: (s, _, sub) => (..s, elem: sub),
    suffix: s => none,
    labels: s => ("[]",),
    bad-segment: (s, seg) => (
      "lens segment for an array schema must be \"items\", got "
        + repr(seg)
        + "."
    ),
    constructors: (array-of,),
  ),
  // Fields in key order, so every walk is diff-stable whatever order
  // the source declared them in; then the additional schema when it
  // is one. A field literally named "additionalProperties" shadows the
  // additional schema, as in lens paths: reach that through the parent.
  object: _kind(
    walk: _object-walk,
    leaf: false,
    searchable: false,
    children: s => {
      let pairs = s.shape.pairs().sorted(key: p => p.at(0))
      let additional = s.at("additional", default: none)
      if type(additional) == dictionary {
        pairs + (("additionalProperties", additional),)
      } else { pairs }
    },
    // Through object(), so a lens write keeps its invariants.
    with-child: (s, seg, sub) => if seg in s.shape {
      // Typst dicts are values: this copy leaves `s` untouched.
      let shape = s.shape
      shape.insert(seg, sub)
      _object-with(s, shape: shape)
    } else { _object-with(s, additional: sub) },
    suffix: s => none,
    // A required field is marked `name*`; the additional schema shows
    // as `*`, the display-only key for "any other key".
    labels: s => {
      let fields = s
        .shape
        .keys()
        .sorted()
        .map(k => if k in s.at("required-keys", default: ()) { k + "*" } else {
          k
        })
      if type(s.at("additional", default: none)) == dictionary {
        fields + ("*",)
      } else { fields }
    },
    bad-segment: (s, seg) => if seg == "additionalProperties" {
      (
        "lens segment \"additionalProperties\" requires the object's "
          + "`additional` field to be a schema dict, got: "
          + repr(s.at("additional", default: none))
          + "."
      )
    } else {
      (
        "lens path segment "
          + repr(seg)
          + " not in object shape. "
          + "Valid keys: "
          + s.shape.keys().join(", ")
          + "."
      )
    },
    constructors: (object, map),
  ),
  // A member's segment is its index, so a path doesn't say whether it
  // went through any-of or one-of.
  union: _kind(
    walk: _union-walk,
    leaf: false,
    children: s => s.members.enumerate(),
    with-child: (s, i, sub) => {
      // Typst arrays are values: this copy leaves `s` untouched.
      let members = s.members
      members.at(i) = sub
      (..s, members: members)
    },
    bad-segment: (s, seg) => (
      "lens segment for a union schema must be a member index, 0 to "
        + str(s.members.len() - 1)
        + ", got "
        + repr(seg)
        + "."
    ),
    // The header says which union; the members are listed below it.
    suffix: s => if s.exclusive { "one of" } else { "any of" },
    labels: s => range(s.members.len()).map(i => "[" + str(i) + "]"),
    // `nullable(X)`, an any-of of exactly X then null, draws as `X?`.
    shorthand: s => if s == nullable(s.members.first()) {
      (of: s.members.first(), mark: "?")
    },
    constructors: (any-of, one-of, nullable),
  ),
  "not": _kind(
    walk: _not-walk,
    leaf: false,
    children: s => (("not", s.member),),
    with-child: (s, _, sub) => (..s, member: sub),
    bad-segment: (s, seg) => (
      "lens segment for a not schema must be \"not\", got " + repr(seg) + "."
    ),
    // No header: the member's label, its lens segment, says it.
    suffix: s => none,
    labels: s => ("not",),
    constructors: (not-of,),
  ),
)

// Every exported constant names a registered kind, and every exported
// constructor is listed by some descriptor, so a new kind can't miss
// its descriptor. `dictionary(module)` lists a module's names.
#let _check-coverage(kinds, modules) = {
  for mod in modules {
    for (name, v) in dictionary(mod) {
      if name.starts-with("_") { continue }
      if type(v) == dictionary {
        assert(
          v.at("kind", default: none) in kinds,
          message: "gairm-import: internal — "
            + name
            + " has kind "
            + repr(v.at("kind", default: none))
            + ", which has no descriptor.",
        )
      } else if type(v) == function {
        assert(
          kinds.values().any(d => v in d.constructors),
          message: "gairm-import: internal — constructor "
            + name
            + " is in no descriptor's constructors.",
        )
      }
    }
  }
}

#_check-coverage(_kinds, (_leaf-mod, _format-mod, _structure-mod))

// Every registered kind tells the engine how to judge and model a
// value: a `check` or a `walk`.
#let _check-engine(kinds) = {
  for (name, d) in kinds {
    assert(
      d.check != none or d.walk != none,
      message: "gairm-import: internal — kind "
        + repr(name)
        + " has neither a check nor a walk.",
    )
  }
}

#_check-engine(_kinds)

// The constructors' schema check (_require-schema) knows the kinds by
// name, since it sits below this registry: the two lists must agree.
#let _check-kind-names(kinds, names) = {
  assert(
    kinds.keys().sorted() == names.sorted(),
    message: "gairm-import: internal — the registered kinds "
      + repr(kinds.keys().sorted())
      + " differ from structure.typ's _schema-kinds "
      + repr(names.sorted())
      + ".",
  )
}

#_check-kind-names(_kinds, _schema-kinds)

// A node of a kind the registry doesn't know (hand-built) behaves as a
// leaf, as it did before the registry.
#let _descriptor(s) = _kinds.at(s.kind, default: _kind())
