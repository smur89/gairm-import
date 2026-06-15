// schema-from-json-schema turns a parsed JSON Schema dict into a
// Typst schema dict consumable by validate / coerce. Unit-test each
// mapping row plus the unsupported-keyword panics by source-reading.

#import "../lib.typ": (
  schema-from-json-schema,
  str-type, number-type, array-of, object,
)

// Primitive types.
#assert.eq(schema-from-json-schema((type: "string")), str-type)
#assert.eq(schema-from-json-schema((type: "number")), number-type)
#assert.eq(schema-from-json-schema((type: "integer")), number-type)

// Strings with format degrade to str-type for now — once #10
// (format validation) lands, format-aware combinators kick in.
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

// Array.
#assert.eq(
  schema-from-json-schema((type: "array", items: (type: "string"))),
  array-of(str-type),
)

// Nested array.
#assert.eq(
  schema-from-json-schema((
    type: "array",
    items: (type: "array", items: (type: "number")),
  )),
  array-of(array-of(number-type)),
)

// Object: properties + required.
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

// Object without "required" → empty required list.
#let loose = schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
))
#assert.eq(loose.required-keys, ())

// Object with no properties at all → empty shape.
#let empty = schema-from-json-schema((type: "object"))
#assert.eq(empty.kind, "object")
#assert.eq(empty.shape, (:))

// Internal $ref resolution against the document root.
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

// Nested $ref inside an array.
#let array-of-refs = schema-from-json-schema((
  "$defs": (item: (type: "string")),
  type: "array",
  items: ("$ref": "#/$defs/item"),
))
#assert.eq(array-of-refs, array-of(str-type))
