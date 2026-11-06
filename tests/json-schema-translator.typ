#import "../lib.typ": (
  schema-from-json-schema, str-type, number-type, integer-type, array-of,
  object, date-string, datetime-string, uri-string, email-string, uuid-string,
  hostname-string, ipv4-string, ipv6-string, time-string, pattern-string,
  enum-of, const-of, bool-type, any-of, number,
)

#assert.eq(schema-from-json-schema((type: "string")), str-type)
#assert.eq(schema-from-json-schema((type: "number")), number-type)
// `integer` keeps its integral constraint — it is not flattened to
// plain number (that would silently drop the constraint).
#assert.eq(schema-from-json-schema((type: "integer")), integer-type)

// Format keywords map to format-specialised string kinds.
#assert.eq(
  schema-from-json-schema((type: "string", format: "uri")),
  uri-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "email")),
  email-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "date")),
  date-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "date-time")),
  datetime-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "uuid")),
  uuid-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "hostname")),
  hostname-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "ipv4")),
  ipv4-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "ipv6")),
  ipv6-string,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "time")),
  time-string,
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
#assert.eq(person-typst.shape.age, integer-type)
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

// $ref is an RFC 6901 pointer: `~1` is `/`, `~0` is `~`, and a numeric
// segment indexes an array. (An empty segment is the "" key, so a
// trailing slash no longer resolves — see
// tests/panics/json-schema-ref-trailing-slash.typ.)
#let escaped = schema-from-json-schema((
  definitions: (
    "a/b": (type: "string"),
    "a~b": (type: "number"),
    pair: (anyOf: ((type: "string"), (type: "integer"))),
  ),
  type: "object",
  properties: (
    slash: ("$ref": "#/definitions/a~1b"),
    tilde: ("$ref": "#/definitions/a~0b"),
    indexed: ("$ref": "#/definitions/pair/anyOf/1"),
  ),
))
#assert.eq(escaped.shape.slash, str-type)
#assert.eq(escaped.shape.tilde, number-type)
#assert.eq(escaped.shape.indexed, integer-type)

// The `$ref` is a URI fragment, so it is percent-decoded before it is
// read as a pointer (RFC 3986, then RFC 6901); adapted from the JSON
// Schema test suite's "refs with quote" and "$ref to key containing
// percent" cases. An escape-free ref resolves as before.
#let percent = schema-from-json-schema((
  definitions: (
    "a%b": (type: "string"),
    "a\"b": (type: "number"),
    "a~b c": (type: "boolean"),
    plain: (type: "integer"),
    "café": (type: "string"),
  ),
  type: "object",
  properties: (
    utf8: ("$ref": "#/definitions/caf%C3%a9"),
    percent: ("$ref": "#/definitions/a%25b"),
    quote: ("$ref": "#/definitions/a%22b"),
    tilde-space: ("$ref": "#/definitions/a~0b%20c"),
    plain: ("$ref": "#/definitions/plain"),
  ),
))
#assert.eq(percent.shape.percent, str-type)
#assert.eq(percent.shape.quote, number-type)
#assert.eq(percent.shape.tilde-space, bool-type)
#assert.eq(percent.shape.plain, integer-type)
#assert.eq(percent.shape.utf8, str-type)

// enum maps to enum-of regardless of accompanying `type`. The values
// array is preserved verbatim; the type keyword (if present) is
// redundant because enum-membership already constrains shape.
#assert.eq(
  schema-from-json-schema((enum: ("a", "b", "c"))),
  enum-of(("a", "b", "c")),
)
#assert.eq(
  schema-from-json-schema((type: "string", enum: ("a", "b"))),
  enum-of(("a", "b")),
)
// Mixed-type enums round-trip too.
#assert.eq(
  schema-from-json-schema((enum: (1, "two", 3.0))),
  enum-of((1, "two", 3.0)),
)

// const maps to const-of, the singleton-enum convenience.
#assert.eq(
  schema-from-json-schema((const: "v1.0.0")),
  const-of("v1.0.0"),
)
#assert.eq(
  schema-from-json-schema((type: "string", const: "fixed")),
  const-of("fixed"),
)

// Constraint keywords beside enum / const fold into the value set: only
// values that satisfy them survive.
#assert.eq(
  schema-from-json-schema((enum: (1, 5, 20), minimum: 4)),
  enum-of((5, 20)),
)
#assert.eq(
  schema-from-json-schema((
    enum: ("a", "bb", "ccc"),
    minLength: 2,
    maxLength: 2,
  )),
  enum-of(("bb",)),
)
#assert.eq(
  schema-from-json-schema((enum: ("ab1", "abc", "x"), pattern: "^ab")),
  enum-of(("ab1", "abc")),
)
// `type` beside enum / const filters values too.
#assert.eq(
  schema-from-json-schema((type: "integer", enum: (1.5, 2, 3.0))),
  enum-of((2, 3.0)),
)
#assert.eq(
  schema-from-json-schema((type: "string", enum: ("a", 1))),
  enum-of(("a",)),
)
#assert.eq(
  schema-from-json-schema((type: ("string", "null"), enum: ("a", 1, none))),
  enum-of(("a", none)),
)
// An empty enum stays as it always was.
#assert.eq(schema-from-json-schema((enum: ())), enum-of(()))
// A string value must satisfy format AND pattern.
#assert.eq(
  schema-from-json-schema((
    enum: ("a@x.io", "b@y.io", "nope"),
    format: "email",
    pattern: "^a",
  )),
  enum-of(("a@x.io",)),
)
#assert.eq(
  schema-from-json-schema((enum: ((1,), (1, 2), (3,)), minItems: 2)),
  enum-of(((1, 2),)),
)
#assert.eq(
  schema-from-json-schema((const: 5, minimum: 4)),
  const-of(5),
)
// Type-specific keywords ignore other types, so values of a type the
// keyword does not apply to survive.
#assert.eq(
  schema-from-json-schema((enum: (1, "x", true, none), minimum: 4)),
  enum-of(("x", true, none)),
)

// Equality holds because Typst's regex compares by source.
#assert.eq(
  schema-from-json-schema((type: "string", pattern: "^[A-Z]{2}$")),
  pattern-string("^[A-Z]{2}$", expected: "matching " + repr("^[A-Z]{2}$")),
)

#let x-gate = (pattern: regex("^x$"), expected: "matching " + repr("^x$"))

// Format and pattern compose — the format kind carries the pattern as
// an extra gate, with the same hint a bare pattern would get.
#assert.eq(
  schema-from-json-schema((type: "string", format: "email", pattern: "^x$")),
  email-string + x-gate,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "uri", pattern: "^x$")),
  uri-string + x-gate,
)
#assert.eq(
  schema-from-json-schema((type: "string", format: "date", pattern: "^x$")),
  date-string + x-gate,
)
#assert.eq(
  schema-from-json-schema((
    type: "string",
    format: "date-time",
    pattern: "^x$",
  )),
  datetime-string + x-gate,
)

// bytes entry mirrors path and dict.
#assert.eq(
  schema-from-json-schema(bytes("{\"type\": \"string\"}")),
  str-type,
)

// A `type` array builds each member from the whole node, and each
// member ignores the other types' keywords, as in draft 7. A keyword
// for none of the node's types bails instead (tests/panics/).
#assert.eq(
  schema-from-json-schema((type: ("string", "number"), minimum: 1)),
  any-of((str-type, number(minimum: 1))),
)
