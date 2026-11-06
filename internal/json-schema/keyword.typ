// The translator's keywords, one entry each: `role` says where the
// translator consumes it, and `types` which JSON types it applies to
// (a keyword without `types` applies to every node). The allow-list,
// the sibling rule beside a composition keyword or `$ref`, the
// unsupported-keyword bails and the enum/const structural list all
// read this table, so a new keyword is one entry here plus the code
// that consumes it.

#import "../kinds/constraint.typ": _constraint-rows

// One panic prefix so every diagnostic from the translator is grep-able
// by "schema-from-json-schema —".
#let _bail(msg) = panic("gairm-import: schema-from-json-schema — " + msg)

// The constraint family each JSON type reads its rows from: `integer`
// is a number. Types not listed take no constraint keyword.
#let _constraint-family = (
  string: "string",
  number: "number",
  integer: "number",
  array: "array",
)

// Annotation-only: no validation semantics the engine could drop, so
// tolerated anywhere, beside a composition keyword or `$ref` too.
#let _annotation = (role: "annotation")
#let _base(t) = (role: "base", types: (t,))
#let _conditional = (
  role: "unsupported",
  reason: "Conditional schemas (if/then/else, dependentSchemas, schema-form dependencies) are out of scope.",
)
// Draft 7 keywords outside the subset, with no reason of their own:
// they bail with any unknown key, as translating would drop them.
#let _outside = (role: "unsupported")

// Order is diagnostic order: the composition keywords before `$ref` for
// the sibling rule, and the structural keywords for enum/const as listed.
#let _keywords = (
  "$schema": _annotation,
  "$id": _annotation,
  "$comment": _annotation,
  title: _annotation,
  description: _annotation,
  default: _annotation,
  examples: _annotation,
  readOnly: _annotation,
  writeOnly: _annotation,
  deprecated: _annotation,
  definitions: _annotation,
  "$defs": _annotation,
  // Composition keywords (#108) and `$ref` stand alone on their node.
  allOf: (role: "applicator"),
  anyOf: (role: "applicator"),
  oneOf: (role: "applicator"),
  "not": (role: "applicator"),
  "$ref": (role: "ref"),
  enum: (role: "membership"),
  const: (role: "membership"),
  type: (role: "type"),
  format: _base("string"),
  pattern: _base("string"),
  properties: _base("object"),
  required: _base("object"),
  additionalProperties: _base("object"),
  items: _base("array"),
  // `dependentRequired` (2019-09) and draft 7's array-form
  // `dependencies` are the same constraint.
  dependentRequired: _base("object"),
  dependencies: _base("object"),
  .._constraint-rows
    .map(row => (
      row.json,
      (
        role: "constraint",
        types: _constraint-family
          .keys()
          .filter(t => _constraint-family.at(t) == row.family),
      ),
    ))
    .to-dict(),
  "if": _conditional,
  then: _conditional,
  "else": _conditional,
  dependentSchemas: _conditional,
  additionalItems: _outside,
  contains: _outside,
  maxProperties: _outside,
  minProperties: _outside,
  patternProperties: _outside,
  propertyNames: _outside,
  contentMediaType: _outside,
  contentEncoding: _outside,
)

#let _role-of(keyword) = _keywords.at(keyword, default: _outside).role

// Whether `js` carries a keyword that applies to JSON type `t` alone.
#let _has-keyword-for(js, t) = (
  js
    .keys()
    .any(k => t in _keywords.at(k, default: (:)).at("types", default: ()))
)

// Object / array structure, which an enum / const value list cannot be
// filtered by: these bail beside enum / const rather than being dropped.
#let _membership-structural = (
  _keywords
    .keys()
    .filter(k => (
      _role-of(k) == "base"
        and _keywords.at(k).types.any(t => t in ("array", "object"))
    ))
)

// What to do with siblings, per role that must stand alone: a sibling
// `type` / `properties` / constraint would be silently ignored, and the
// translator bails rather than drops.
#let _lone-hints = (
  applicator: ". Move them into the composition members.",
  ref: ". Draft 7 ignores them; move them into the referenced definition.",
)

// Bails on a keyword the translator cannot honour: a sibling beside a
// composition keyword or `$ref` (checked before the `$ref` is resolved,
// which would drop it), an unsupported keyword with a reason of its
// own, then every unknown or outside-the-subset key at once (a typo
// like `minLenght` included: draft 7 would ignore it).
#let _check-keywords(js) = {
  for (keyword, entry) in _keywords {
    if keyword not in js or entry.role not in _lone-hints { continue }
    let extras = js
      .keys()
      .filter(k => k != keyword and _role-of(k) != "annotation")
    if extras.len() > 0 {
      _bail(
        "sibling keywords beside "
          + repr(keyword)
          + " are not supported: "
          + extras.map(repr).join(", ")
          + _lone-hints.at(entry.role),
      )
    }
  }
  for (keyword, entry) in _keywords {
    if keyword in js and "reason" in entry {
      _bail(
        "unsupported JSON Schema keyword: "
          + repr(keyword)
          + ". "
          + entry.reason,
      )
    }
  }
  let unknown = js.keys().filter(k => _role-of(k) == "unsupported")
  if unknown.len() > 0 {
    _bail(
      "unsupported JSON Schema keyword(s): "
        + unknown.map(repr).join(", ")
        + ". They are outside the supported subset (see the README); translating would silently drop their constraints.",
    )
  }
}
