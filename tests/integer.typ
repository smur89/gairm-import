// `integer` is its own kind (#162): introspection tells integers from
// numbers, while validation and coercion judge them as before (the
// number checks plus the integral gate).

#import "../lib.typ": (
  integer-type, number-type, str-type, object, array-of, nullable, any-of,
  kind-at, paths-of-kind, describe-schema, schema-from-json-schema, validate,
  coerce, not-of,
)

#assert.eq(integer-type.kind, "integer")
#assert.eq(integer-type, (kind: "integer"))

#let schema = object((
  age: integer-type,
  score: number-type,
  name: str-type,
  counts: array-of(integer-type),
  maybe: nullable(integer-type),
))

#assert.eq(kind-at(schema, ("age",)), "integer")
#assert.eq(kind-at(schema, ("score",)), "number")
#assert.eq(paths-of-kind(schema, integer-type), (
  ("age",),
  ("counts", "items"),
  ("maybe", 0),
))
#assert.eq(paths-of-kind(schema, number-type), (("score",),))

// describe-schema names the kind; the flag no longer shows as an extra.
#assert.eq(describe-schema(integer-type), "integer")
#assert.eq(
  describe-schema((..integer-type, minimum: 0)),
  "integer (minimum 0)",
)

// The translator's `type: "integer"` emits the kind, constraints and
// all.
#let translated = schema-from-json-schema((type: "integer", minimum: 1))
#assert.eq(translated, (kind: "integer", minimum: 1))
#assert.eq(kind-at(translated, ()), "integer")

// Validation unchanged: the number gate, the integral gate, then the
// number rows.
#assert.eq(validate(2, schema: integer-type), ())
#assert.eq(validate(2.0, schema: integer-type), ())
#assert.eq(validate(1.5, schema: integer-type).map(e => e.code), ("integer",))
#assert.eq(validate("x", schema: integer-type).map(e => e.code), ("type",))
#assert.eq(
  validate(1.5, schema: (..integer-type, minimum: 2)).map(e => e.code),
  ("integer", "range"),
)
#assert.eq(
  validate(1, schema: (..integer-type, minimum: 2)).map(e => e.code),
  ("range",),
)
#assert.eq(coerce(3, schema: integer-type), 3)

// `["number", "integer"]` overlaps and still takes 1 and 1.5.
#let overlap = schema-from-json-schema((type: ("number", "integer")))
#assert.eq(overlap, any-of((number-type, integer-type)))
#assert.eq(validate(1, schema: overlap), ())
#assert.eq(validate(1.5, schema: overlap), ())

// Union and `not` errors still name an integer member `number`, as
// they did before it was a kind of its own.
#let int-or-str = any-of((integer-type, str-type))
#assert.eq(
  validate((1, 2), schema: int-or-str).at(0).message,
  "expected a value matching one of: number | str; none matched.",
)
#assert.eq(
  validate(1, schema: not-of(integer-type)).at(0).message,
  "expected a value not matching the negated number schema.",
)
