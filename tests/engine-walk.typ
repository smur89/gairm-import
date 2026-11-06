// validate, coerce and parse derive from one walk over schema and
// value (#168). These pin what that walk changed or must keep: how
// deep it goes, what an overlapping union costs, what unique-items
// compares, and where coerce still panics or doesn't.

#import "../lib.typ": (
  validate, coerce, parse, str-type, number-type, date-string, array-of, object,
  any-of, one-of, not-of,
)

// ---- depth ---------------------------------------------------------------
//
// Each nesting level costs two call frames against Typst's limit (the
// walk, then the kind's walk), so about 38 levels fit. Real documents
// nest under 10; 30 is the floor this pins.

#let nested-arrays(n) = {
  let schema = str-type
  let value = "x"
  for _ in range(n) {
    schema = array-of(schema)
    value = (value,)
  }
  (schema, value)
}
#let nested-objects(n) = {
  let schema = str-type
  let value = "x"
  for _ in range(n) {
    schema = object((a: schema))
    value = (a: value)
  }
  (schema, value)
}

#let (deep-array, deep-array-value) = nested-arrays(30)
#assert.eq(validate(deep-array-value, schema: deep-array), ())
#assert.eq(coerce(deep-array-value, schema: deep-array), deep-array-value)
#let (deep-object, deep-object-value) = nested-objects(30)
#assert.eq(validate(deep-object-value, schema: deep-object), ())
#assert.eq(parse(deep-object-value, schema: deep-object), deep-object-value)

// ---- overlapping unions -------------------------------------------------
//
// Every level of `any-of((s, number, array-of(s)))` tries `s` and
// `array-of(s)` against the same value. parse used to validate, then
// re-validate members to pick one for the model, which took about 1 s
// at 17 levels; the walk keeps the first clean member's output, so this
// compiles in well under a second.

#let overlapping = {
  let s = str-type
  for _ in range(17) { s = any-of((s, number-type, array-of(s))) }
  s
}
#let deep-value = {
  let v = "x"
  for _ in range(17) { v = (v,) }
  v
}
#assert.eq(
  parse((a: deep-value), schema: object((a: overlapping))),
  (a: deep-value),
)

// ---- unique-items compares the walked items -----------------------------
//
// A free-form object keeps its nulls in the model, so two items that
// differ only by a null key there are distinct, and validate agrees
// with what coerce returns.
#let free-form = object((:), additional: true)
#let unique-bags = (..array-of(free-form), unique-items: true)
#assert.eq(validate(((a: none), (:)), schema: unique-bags), ())
#assert.eq(coerce(((a: none), (:)), schema: unique-bags), ((a: none), (:)))
// Null keys in a declared shape are still dropped before comparing.
#let unique-shaped = (..array-of(object((a: str-type))), unique-items: true)
#assert.eq(
  validate(((a: none), (:)), schema: unique-shaped).map(e => e.code),
  ("unique",),
)
// A `not` passes its value through as given, nulls included, so these
// two are distinct too.
#let unique-not = (..array-of(not-of(number-type)), unique-items: true)
#assert.eq(validate(((a: 1, b: none), (a: 1)), schema: unique-not), ())
// A datetime and the ISO string it coerces to are the same item.
#let unique-dates = (..array-of(date-string), unique-items: true)
#assert.eq(
  validate(
    ("2024-01-02", datetime(year: 2024, month: 1, day: 2)),
    schema: unique-dates,
  ).map(e => e.code),
  ("unique",),
)

// ---- where coerce panics ------------------------------------------------
//
// A one-of with several matching members is a validation error, but
// the first match still models the value, so coerce returns it.
#let either = one-of((str-type, str-type))
#assert.eq(validate("x", schema: either).map(e => e.code), ("union",))
#assert.eq(coerce("x", schema: either), "x")
