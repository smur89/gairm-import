// bool-type / null-type / [X, "null"] union — #75.

#import "../lib.typ": (
  validate, coerce,
  schema-from-json-schema,
  bool-type, null-type,
  str-type, integer-type, email-string, object,
  paths-of-kind,
)

// --- bool-type --------------------------------------------------------

#assert.eq(validate(true, schema: bool-type), ())
#assert.eq(validate(false, schema: bool-type), ())
#assert.eq(coerce(true, schema: bool-type), true)
#assert.eq(coerce(false, schema: bool-type), false)

// Type errors carry the path-qualified "expected boolean" message.
#let bool-errs = validate("yes", schema: bool-type)
#assert.eq(bool-errs.len(), 1)
#assert(bool-errs.at(0).message.contains("expected boolean"))
#assert(bool-errs.at(0).message.contains("got string"))

// --- null-type --------------------------------------------------------
//
// Null root is rejected by the lib.typ wrapper, so test through a
// nested-in-object position.
#let nested = object((flag: null-type))
#assert.eq(validate((flag: none), schema: nested), ())
#let null-errs = validate((flag: 1), schema: nested)
#assert.eq(null-errs.len(), 1)
#assert(null-errs.at(0).message.contains("expected null"))

// --- translator: type: "boolean" / "null" ----------------------------

#assert.eq(
  schema-from-json-schema((type: "boolean")),
  bool-type,
)
#assert.eq(
  schema-from-json-schema((type: "null")),
  null-type,
)

// --- translator: [X, "null"] nullable union --------------------------
//
// Translates to plain X — a wrapper would be a no-op under
// null-as-absent.

#assert.eq(
  schema-from-json-schema((type: ("string", "null"))),
  str-type,
)
// Order doesn't matter — `null` can come first. The inner type keeps
// its own semantics (`integer` stays integral-gated).
#assert.eq(
  schema-from-json-schema((type: ("null", "integer"))),
  integer-type,
)
// Sibling keywords on the union carry through to the inner.
#assert.eq(
  schema-from-json-schema((type: ("string", "null"), format: "email")),
  email-string,
)

// --- introspection: new kinds register as leaves --------------------

#let mixed = object((flag: bool-type, marker: null-type, name: str-type))
#assert.eq(paths-of-kind(mixed, "bool"), (("flag",),))
#assert.eq(paths-of-kind(mixed, "null"), (("marker",),))

// --- translator: multi-non-null union rejected -----------------------
//
// Source-level pin on the bail message — Typst can't catch panics so
// this is the closest available proxy. Same pattern as
// tests/json_schema_panic_messages.typ.
#let src = read("../internal/json-schema.typ")
#assert(src.contains("only supported as nullable wraps"))
