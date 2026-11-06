// One descriptor per schema kind, so lens, introspection and the
// strict-schema walkers ask the registry instead of keeping their own
// `kind ==` ladders. A descriptor holds:
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

#import "leaf.typ" as _leaf-mod
#import "leaf.typ": pattern-string, enum-of, const-of
#import "format.typ" as _format-mod
#import "structure.typ" as _structure-mod
#import "structure.typ": array-of, object, map, any-of, one-of, not-of

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
) = (
  leaf: leaf,
  children: children,
  with-child: with-child,
  suffix: suffix,
  bad-segment: bad-segment,
  constructors: constructors,
)

// A format kind with an extra pattern gate (JSON Schema format +
// pattern) says so.
#let _format-kind = _kind(suffix: s => if "pattern" in s {
  s.kind + " + pattern"
} else { s.kind })

#let _kinds = (
  str: _kind(),
  content: _kind(),
  number: _kind(),
  bool: _kind(),
  null: _kind(),
  .._format-mod._formats.keys().map(k => (k, _format-kind)).to-dict(),
  pattern-string: _kind(constructors: (pattern-string,)),
  // The values inline, for at-a-glance debugging.
  enum: _kind(
    suffix: s => "enum (" + s.values.map(repr).join(", ") + ")",
    constructors: (enum-of, const-of),
  ),
  array: _kind(
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
    suffix: s => (
      (if s.exclusive { "one of" } else { "any of" })
        + " ("
        + s.members.map(m => m.kind).join(" | ")
        + ")"
    ),
    constructors: (any-of, one-of),
  ),
  "not": _kind(
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

// A node of a kind the registry doesn't know (hand-built) behaves as a
// leaf, as it did before the registry.
#let _descriptor(s) = _kinds.at(s.kind, default: _kind())
