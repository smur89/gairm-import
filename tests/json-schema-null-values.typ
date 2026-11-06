// A JSON null is a value only where null means something: `const: null`
// (the value must be null), a null among the `enum` values, and an
// annotation. Beside any other keyword it panics (see
// tests/panics/json-schema-keyword-null.typ) rather than reading as
// absent.

#import "../lib.typ": schema-from-json-schema, enum-of, str-type

#assert.eq(schema-from-json-schema((const: none)), enum-of((none,)))
#assert.eq(
  schema-from-json-schema((enum: ("a", none))),
  enum-of(("a", none)),
)
#assert.eq(
  schema-from-json-schema((
    type: "string",
    title: none,
    description: none,
    default: none,
    examples: none,
  )),
  str-type,
)
