// `integer` is its own kind (#162): introspection tells integers from
// numbers, while validation and coercion judge them as before (the
// number checks plus the integral gate).

#import "../lib.typ": (
  object, array-of, nullable, any-of, paths-of-kind, describe-schema,
  schema-from-json-schema, validate, coerce, not-of, string, number, integer,
  lens-get,
)


#let schema = object((
  age: integer(),
  score: number(),
  name: string(),
  counts: array-of(integer()),
  maybe: nullable(integer()),
))

#assert.eq(lens-get(schema, ("age",)).kind, "integer")
#assert.eq(lens-get(schema, ("score",)).kind, "number")
#assert.eq(paths-of-kind(schema, integer()), (
  ("age",),
  ("counts", "items"),
  ("maybe", 0),
))
#assert.eq(paths-of-kind(schema, number()), (("score",),))

// describe-schema names the kind.
#assert.eq(describe-schema(integer()), "integer")
#assert.eq(
  describe-schema((..integer(), minimum: 0)),
  "integer (minimum 0)",
)

// The translator's `type: "integer"` emits the kind, constraints and
// all.
#let translated = schema-from-json-schema((type: "integer", minimum: 1))
#assert.eq(translated, (kind: "integer", minimum: 1))
#assert.eq(lens-get(translated, ()).kind, "integer")

// Validation unchanged: the number gate, the integral gate, then the
// number rows.
#assert.eq(validate(integer(), 2), ())
#assert.eq(validate(integer(), 2.0), ())
#assert.eq(validate(integer(), 1.5).map(e => e.code), ("integer",))
#assert.eq(validate(integer(), "x").map(e => e.code), ("type",))
#assert.eq(
  validate((..integer(), minimum: 2), 1.5).map(e => e.code),
  ("integer", "range"),
)
#assert.eq(
  validate((..integer(), minimum: 2), 1).map(e => e.code),
  ("range",),
)
#assert.eq(coerce(integer(), 3), 3)

// `["number", "integer"]` overlaps and still takes 1 and 1.5.
#let overlap = schema-from-json-schema((type: ("number", "integer")))
#assert.eq(overlap, any-of((number(), integer())))
#assert.eq(validate(overlap, 1), ())
#assert.eq(validate(overlap, 1.5), ())

// Union and `not` errors name an integer member `integer`.
#let int-or-str = any-of((integer(), string()))
#assert.eq(
  validate(int-or-str, (1, 2)).at(0).message,
  "expected a value matching one of: integer | string; none matched.",
)
#assert.eq(
  validate(not-of(integer()), 1).at(0).message,
  "expected a value not matching the negated integer schema.",
)

// Bounds must leave an integer, not just a number; ones that do are
// fine however they are written.
#assert.eq(integer(minimum: 1.5, maximum: 2).maximum, 2)
#assert.eq(integer(exclusive-minimum: 1, maximum: 2).maximum, 2)
#assert.eq(integer(minimum: -1.5, exclusive-maximum: -0.5).minimum, -1.5)
#assert.eq(integer(minimum: 1e300, maximum: 1e300).minimum, 1e300)

// An infinite bound restricts nothing, and an exclusive bound at the
// int limit steps past it in float rather than overflowing.
#assert.eq(validate(integer(minimum: -calc.inf, maximum: calc.inf), 0), ())
#assert.eq(
  integer(exclusive-minimum: 9223372036854775807, maximum: 1e20).maximum,
  1e20,
)
// In a `type` list, an integer member with no integer in its bounds is
// dropped; the number member still takes 1.6.
#let num-or-int = schema-from-json-schema((
  type: ("number", "integer"),
  minimum: 1.5,
  maximum: 1.7,
))
#assert.eq(num-or-int.kind, "number")
#assert.eq(validate(num-or-int, 1.6), ())
// A whole float count fits an int up to 2^63.
#assert.eq(
  schema-from-json-schema((type: "array", maxItems: 9.21e18)).max-items,
  9210000000000000000,
)

// Exclusive steps stay exact near the int limit: a float step would
// round 9100000000000000100 to a multiple of 1024 and see a gap that
// isn't there (9100000000000000101 is between the bounds).
#assert.eq(
  integer(
    exclusive-minimum: 9100000000000000100,
    exclusive-maximum: 9100000000000000102,
  ).exclusive-minimum,
  9100000000000000100,
)
