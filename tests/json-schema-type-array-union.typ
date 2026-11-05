// type: [A, B, ...] with more than one non-null member — #113.
// Translates to any-of over one member per type; "null" members drop.

#import "../lib.typ": (
  validate, schema-from-json-schema, str-type, number-type, any-of,
)

#let su = schema-from-json-schema((type: ("string", "number")))
#assert.eq(su, any-of((str-type, number-type)))
#let schema = schema-from-json-schema((
  type: "object",
  properties: (v: (type: ("string", "number"))),
))
#assert.eq(validate((v: "a"), schema: schema), ())
#assert.eq(validate((v: 3), schema: schema), ())
#assert.eq(validate((v: 1.5), schema: schema), ())
#assert.eq(validate((v: true), schema: schema).len(), 1)
// Null is absent, so it passes without a null member.
#assert.eq(validate((v: none), schema: schema), ())

// Null members drop from the union.
#assert.eq(
  schema-from-json-schema((type: ("string", "number", "null"))),
  any-of((str-type, number-type)),
)
#assert.eq(
  schema-from-json-schema((type: ("null", "null"))),
  schema-from-json-schema((type: "null")),
)

// Type-specific keywords apply only to their own type.
#let constrained = schema-from-json-schema((
  type: "object",
  properties: (
    v: (type: ("string", "integer"), minLength: 3, minimum: 10),
  ),
))
#assert.eq(validate((v: "abc"), schema: constrained), ())
#assert.eq(validate((v: 10), schema: constrained), ())
#assert.eq(validate((v: "ab"), schema: constrained).len() > 0, true)
#assert.eq(validate((v: 9), schema: constrained).len() > 0, true)
// minLength does not constrain numbers; minimum does not constrain strings.
#assert.eq(validate((v: 100), schema: constrained), ())
#assert.eq(validate((v: "a-long-string"), schema: constrained), ())

// Containers as members.
#let mixed = schema-from-json-schema((
  type: "object",
  properties: (v: (type: ("string", "array"), items: (type: "integer"))),
))
#assert.eq(validate((v: "x"), schema: mixed), ())
#assert.eq(validate((v: (1, 2)), schema: mixed), ())
#assert.eq(validate((v: ("x",)), schema: mixed).len() > 0, true)

// Overlapping members stay valid (any-of, not one-of).
#let overlap = schema-from-json-schema((
  type: "object",
  properties: (v: (type: ("number", "integer"))),
))
#assert.eq(validate((v: 1), schema: overlap), ())

// Duplicate type names build one member.
#assert.eq(schema-from-json-schema((type: ("string", "string"))), str-type)

// A right-typed value that breaks a constraint reports that constraint,
// not the generic none-matched summary.
#let short = validate((v: "ab"), schema: constrained)
#assert.eq(short.len(), 1)
#assert(short.at(0).message.contains("string length"))
// A wrong-typed value still gets the generic summary.
#assert(
  validate((v: true), schema: schema).at(0).message.contains("none matched"),
)
