#import "../lib.typ": (
  schema-from-json-schema,
  str-type, number-type, array-of, object,
)

#assert.eq(schema-from-json-schema((type: "string")), str-type)
#assert.eq(schema-from-json-schema((type: "number")), number-type)
#assert.eq(schema-from-json-schema((type: "integer")), number-type)

// Format degrades to str-type until #10 wires format-aware combinators.
#assert.eq(
  schema-from-json-schema((type: "string", format: "uri")),
  str-type,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "email")),
  str-type,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "date")),
  str-type,
)

#assert.eq(
  schema-from-json-schema((type: "array", items: (type: "string"))),
  array-of(str-type),
)

#assert.eq(
  schema-from-json-schema((
    type: "array",
    items: (type: "array", items: (type: "number")),
  )),
  array-of(array-of(number-type)),
)

#let person-js = (
  type: "object",
  properties: (
    name: (type: "string"),
    age: (type: "integer"),
  ),
  required: ("name",),
)
#let person-typst = schema-from-json-schema(person-js)
#assert.eq(person-typst.kind, "object")
#assert.eq(person-typst.shape.name, str-type)
#assert.eq(person-typst.shape.age, number-type)
#assert.eq(person-typst.required-keys, ("name",))

#let loose = schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
))
#assert.eq(loose.required-keys, ())

// Missing `properties` is rejected (open object); explicit `(:)` is
// the strict-empty form.
#let empty = schema-from-json-schema((type: "object", properties: (:)))
#assert.eq(empty.kind, "object")
#assert.eq(empty.shape, (:))

#let with-ref = (
  definitions: (iso8601: (type: "string")),
  type: "object",
  properties: (
    startDate: ("$ref": "#/definitions/iso8601"),
    summary: (type: "string"),
  ),
)
#let resolved = schema-from-json-schema(with-ref)
#assert.eq(resolved.shape.startDate, str-type)
#assert.eq(resolved.shape.summary, str-type)

#let array-of-refs = schema-from-json-schema((
  "$defs": (item: (type: "string")),
  type: "array",
  items: ("$ref": "#/$defs/item"),
))
#assert.eq(array-of-refs, array-of(str-type))

// alias → real def: chained $refs resolve to the final type.
#let chained = schema-from-json-schema((
  definitions: (
    alias: ("$ref": "#/definitions/iso8601"),
    iso8601: (type: "string"),
  ),
  type: "object",
  properties: (
    startDate: ("$ref": "#/definitions/alias"),
  ),
))
#assert.eq(chained.shape.startDate, str-type)

// Trailing-slash $ref tolerated — empty path segments dropped.
#let trailing = schema-from-json-schema((
  definitions: (foo: (type: "string")),
  type: "object",
  properties: (
    x: ("$ref": "#/definitions/foo/"),
  ),
))
#assert.eq(trailing.shape.x, str-type)
