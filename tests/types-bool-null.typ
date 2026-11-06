// bool-type / null-type / [X, "null"] union — #75.

#import "../lib.typ": (
  validate, coerce, schema-from-json-schema, bool-type, null-type, str-type,
  integer-type, email-string, object, paths-of-kind, nullable,
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
// Translates to nullable(X): X under null-as-absent, and the way a
// field accepts null under strict-null.

#assert.eq(
  schema-from-json-schema((type: ("string", "null"))),
  nullable(str-type),
)
// Order doesn't matter — `null` can come first. The inner type keeps
// its own semantics (`integer` stays integral-gated).
#assert.eq(
  schema-from-json-schema((type: ("null", "integer"))),
  nullable(integer-type),
)
// Sibling keywords on the union carry through to the inner.
#assert.eq(
  schema-from-json-schema((type: ("string", "null"), format: "email")),
  nullable(email-string),
)
#assert.eq(
  schema-from-json-schema((type: ("string", "string", "null"))),
  nullable(str-type),
)

// --- introspection: new kinds register as leaves --------------------

#let mixed = object((flag: bool-type, marker: null-type, name: str-type))
#assert.eq(paths-of-kind(mixed, "bool"), (("flag",),))
#assert.eq(paths-of-kind(mixed, "null"), (("marker",),))
