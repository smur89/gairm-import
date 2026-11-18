// Mirrors REFERENCE.md, "JSON Schema translation": the equality it
// states, and the deviations from draft 7 that come with an example.
// The schemas are ours.
#import "@preview/gairm-import:0.0.0": *

#assert.eq(
  schema-from-json-schema((type: "string", minLength: 3)),
  string(min-length: 3),
)
#assert.eq(
  schema-from-json-schema((type: ("string", "null"))),
  nullable(string()),
)
#assert.eq(schema-from-json-schema((title: "anything")), any-type)

// A missing additionalProperties is closed.
#let closed = schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
))
#assert.eq(validate(closed, (b: 1)).map(e => e.code), ("unknown-key",))

// String length counts grapheme clusters: e plus a combining accent.
#assert.eq(
  validate(string(min-length: 2), "e\u{301}").map(e => e.got),
  (1,),
)

// multipleOf on floats uses a tolerance.
#assert.eq(validate(number(multiple-of: 0.1), 0.3), ())

// uniqueItems compares items as the model holds them.
#let pairs = schema-from-json-schema((
  type: "array",
  uniqueItems: true,
  items: (
    type: "object",
    properties: (a: (type: "integer"), b: (type: "integer")),
  ),
))
#assert.eq(
  validate(pairs, ((a: 1, b: none), (a: 1))).map(e => e.code),
  ("unique",),
)
#assert.eq(
  validate(pairs, ((a: 1, b: none), (a: 1)), strict-null: true).map(
    e => e.code,
  ),
  ("type",),
)
// A free-form object keeps its nulls, so there the two items differ.
#let bags = schema-from-json-schema((
  type: "array",
  uniqueItems: true,
  items: (type: "object", additionalProperties: true),
))
#assert.eq(validate(bags, ((a: 1, b: none), (a: 1))), ())

// if / then / else beside other keywords: `then: {required: ["b"]}`
// requires a property the node declares, and `if` is open, so it holds
// for an object with more keys than it names.
#let kinded = schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string"), b: (type: "string")),
  "if": (properties: (a: (const: "x"))),
  then: (required: ("b",)),
))
#assert.eq(validate(kinded, (a: "x", b: "y")), ())
#assert.eq(validate(kinded, (a: "y")), ())
#assert.eq(validate(kinded, (a: "x")).map(e => e.code), ("required",))

// integer accepts 1.0 and keeps it a float.
#assert.eq(
  type(coerce(schema-from-json-schema((type: "integer")), 1.0)),
  float,
)
