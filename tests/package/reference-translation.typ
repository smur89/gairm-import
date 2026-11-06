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
#assert.eq(validate((b: 1), schema: closed).map(e => e.code), ("unknown-key",))

// String length counts grapheme clusters: e plus a combining accent.
#assert.eq(
  validate("e\u{301}", schema: string(min-length: 2)).map(e => e.got),
  (1,),
)

// multipleOf on floats uses a tolerance.
#assert.eq(validate(0.3, schema: number(multiple-of: 0.1)), ())

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
  validate(((a: 1, b: none), (a: 1)), schema: pairs).map(e => e.code),
  ("unique",),
)
#assert.eq(
  validate(((a: 1, b: none), (a: 1)), schema: pairs, strict-null: true).map(
    e => e.code,
  ),
  ("type",),
)

// integer accepts 1.0 and keeps it a float.
#assert.eq(
  type(coerce(1.0, schema: schema-from-json-schema((type: "integer")))),
  float,
)
