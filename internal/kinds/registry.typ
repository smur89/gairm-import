// One descriptor per schema kind, so the engine, lens, introspection
// and the strict-schema walkers ask the registry instead of keeping
// their own `kind ==` ladders. A descriptor holds:
//
//   leaf          traversal stops here (unions and `not` do too, for now)
//   children      schema => ((segment, sub-schema), ..), segments as lens
//                 paths spell them
//   with-child    (schema, segment, sub) => the node with that child
//                 replaced
//   suffix        schema => what describe-schema prints for it as a leaf
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
  _null-check, _pattern-check, _enum-check,
)
#import "format.typ" as _format-mod
#import "format.typ": _formats, _format-check
#import "structure.typ" as _structure-mod
#import "structure.typ": (
  array-of, object, map, any-of, one-of, not-of, _array-walk, _object-walk,
  _union-walk, _not-walk,
)

#let _kind(
  leaf: true,
  children: s => (),
  with-child: none,
  suffix: s => s.kind,
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
  children: children,
  with-child: with-child,
  suffix: suffix,
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
  array: _kind(
    walk: _array-walk,
    leaf: false,
    children: s => (("items", s.elem),),
    with-child: (s, _, sub) => (..s, elem: sub),
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
    children: s => {
      let pairs = s.shape.pairs().sorted(key: p => p.at(0))
      let additional = s.at("additional", default: none)
      if type(additional) == dictionary {
        pairs + (("additionalProperties", additional),)
      } else { pairs }
    },
    with-child: (s, seg, sub) => if seg in s.shape {
      // Typst dicts are values: this copy leaves `s` untouched.
      let shape = s.shape
      shape.insert(seg, sub)
      (..s, shape: shape)
    } else { (..s, additional: sub) },
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
  // Members name their kind only, one level deep.
  union: _kind(
    walk: _union-walk,
    suffix: s => (
      (if s.exclusive { "one of" } else { "any of" })
        + " ("
        + s.members.map(m => m.kind).join(" | ")
        + ")"
    ),
    constructors: (any-of, one-of),
  ),
  "not": _kind(
    walk: _not-walk,
    suffix: s => "not " + s.member.kind,
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

// A node of a kind the registry doesn't know (hand-built) behaves as a
// leaf, as it did before the registry.
#let _descriptor(s) = _kinds.at(s.kind, default: _kind())
