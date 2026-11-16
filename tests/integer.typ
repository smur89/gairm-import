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
#assert.eq(validate(2, schema: integer()), ())
#assert.eq(validate(2.0, schema: integer()), ())
#assert.eq(validate(1.5, schema: integer()).map(e => e.code), ("integer",))
#assert.eq(validate("x", schema: integer()).map(e => e.code), ("type",))
#assert.eq(
  validate(1.5, schema: (..integer(), minimum: 2)).map(e => e.code),
  ("integer", "range"),
)
#assert.eq(
  validate(1, schema: (..integer(), minimum: 2)).map(e => e.code),
  ("range",),
)
#assert.eq(coerce(3, schema: integer()), 3)

// `["number", "integer"]` overlaps and still takes 1 and 1.5.
#let overlap = schema-from-json-schema((type: ("number", "integer")))
#assert.eq(overlap, any-of((number(), integer())))
#assert.eq(validate(1, schema: overlap), ())
#assert.eq(validate(1.5, schema: overlap), ())

// Union and `not` errors name an integer member `integer`.
#let int-or-str = any-of((integer(), string()))
#assert.eq(
  validate((1, 2), schema: int-or-str).at(0).message,
  "expected a value matching one of: integer | string; none matched.",
)
#assert.eq(
  validate(1, schema: not-of(integer())).at(0).message,
  "expected a value not matching the negated integer schema.",
)
