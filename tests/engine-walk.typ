// validate, coerce and parse derive from one walk over schema and
// value (#168). These pin what that walk changed or must keep: how
// deep it goes, what an overlapping union costs, what unique-items
// compares, and where coerce still panics or doesn't.

#import "../lib.typ": (
  validate, coerce, parse, array-of, object, any-of, one-of, not-of, nullable,
  string, number, integer, schema-get, schema-put,
)

// ---- depth ---------------------------------------------------------------
//
// Each nesting level costs two call frames against Typst's limit (the
// walk, then the kind's walk), so 37 levels fit when a run function is
// called at the top level. A nullable hands its value on to its member
// in the walk's own frame, so it costs none of its own: 36 levels of
// nullable objects fit. Real documents nest under 10, but the pin is
// the limit itself, so a frame added between the entry point and the
// walk fails here rather than costing a level unnoticed.

#let nested-arrays(n) = {
  let schema = string()
  let value = "x"
  for _ in range(n) {
    schema = array-of(schema)
    value = (value,)
  }
  (schema, value)
}
#let nested-objects(n) = {
  let schema = string()
  let value = "x"
  for _ in range(n) {
    schema = object((a: schema))
    value = (a: value)
  }
  (schema, value)
}

#let (deep-array, deep-array-value) = nested-arrays(37)
#assert.eq(validate(deep-array, deep-array-value), ())
#assert.eq(coerce(deep-array, deep-array-value), deep-array-value)
#let (deep-object, deep-object-value) = nested-objects(37)
#assert.eq(validate(deep-object, deep-object-value), ())
#assert.eq(parse(deep-object, deep-object-value), deep-object-value)
// Built at the top level: inside a function, the constructors' schema
// checks run out of call depth first.
#let deep-nullable = string()
#let deep-nullable-value = "x"
#for _ in range(36) {
  deep-nullable = nullable(object((a: deep-nullable)))
  deep-nullable-value = (a: deep-nullable-value)
}
#assert.eq(validate(deep-nullable, deep-nullable-value), ())
#assert.eq(coerce(deep-nullable, deep-nullable-value), deep-nullable-value)
#assert.eq(
  parse(deep-nullable, deep-nullable-value, strict-null: true),
  deep-nullable-value,
)
// An edit walks its path in two loops, so it reaches one level short of
// validate: the schema check re-reads the nodes it rebuilt.
#let edit-nullable = string()
#for _ in range(35) { edit-nullable = nullable(object((a: edit-nullable))) }
#let edit-path = range(35).map(_ => (0, "a")).flatten()
#let edited = schema-put(edit-nullable, edit-path, integer())
#assert.eq(schema-get(edited, edit-path), integer())

// ---- overlapping unions -------------------------------------------------
//
// Every level of `any-of((s, number, array-of(s)))` tries `s` and
// `array-of(s)` against the same value. parse used to validate, then
// re-validate members to pick one for the model, which took about 1 s
// at 17 levels; the walk keeps the first clean member's output, so this
// compiles in well under a second.

#let overlapping = {
  let s = string()
  for _ in range(17) { s = any-of((s, number(), array-of(s))) }
  s
}
#let deep-value = {
  let v = "x"
  for _ in range(17) { v = (v,) }
  v
}
#assert.eq(
  parse(object((a: overlapping)), (a: deep-value)),
  (a: deep-value),
)

// ---- unique-items compares the walked items -----------------------------
//
// A free-form object keeps its nulls in the model, so two items that
// differ only by a null key there are distinct, and validate agrees
// with what coerce returns.
#let free-form = object((:), additional: true)
#let unique-bags = (..array-of(free-form), unique-items: true)
#assert.eq(validate(unique-bags, ((a: none), (:))), ())
#assert.eq(coerce(unique-bags, ((a: none), (:))), ((a: none), (:)))
// Null keys in a declared shape are still dropped before comparing.
#let unique-shaped = (..array-of(object((a: string()))), unique-items: true)
#assert.eq(
  validate(unique-shaped, ((a: none), (:))).map(e => e.code),
  ("unique",),
)
// A `not` passes its value through as given, nulls included, so these
// two are distinct too.
#let unique-not = (..array-of(not-of(number())), unique-items: true)
#assert.eq(validate(unique-not, ((a: 1, b: none), (a: 1))), ())
// A datetime and the ISO string it coerces to are the same item.
#let unique-dates = (..array-of(string(format: "date")), unique-items: true)
#assert.eq(
  validate(unique-dates, (
    "2024-01-02",
    datetime(year: 2024, month: 1, day: 2),
  )).map(e => e.code),
  ("unique",),
)

// ---- where coerce panics ------------------------------------------------
//
// A one-of with several matching members is a validation error, but
// the first match still models the value, so coerce returns it.
#let either = one-of((string(), string()))
#assert.eq(validate(either, "x").map(e => e.code), ("union",))
#assert.eq(coerce(either, "x"), "x")

// ---- one input rule --------------------------------------------------------
//
// validate, coerce and parse take the same inputs: a path or bytes read
// as JSON, or any other value as the document, whatever root the
// schema takes. A string is a value unless it ends in `.json` and the
// schema's root does not take it (then all three panic with the
// path(..) hint; tests/panics/).
#let numbers = array-of(number())
#assert.eq(parse(numbers, (1, 2)), (1, 2))
#assert.eq(parse(numbers, bytes("[1, 2]")), (1, 2))
#assert.eq(parse(string(format: "date"), "2024-01-15"), "2024-01-15")
// A `.json` string the root takes is a value like any other.
#assert.eq(validate(string(), "notes.json"), ())
#assert.eq(parse(string(), "notes.json"), "notes.json")
// A string the root rejects that names no file is a type error.
#assert.eq(
  validate(object((:)), "notes").map(e => e.code),
  ("type",),
)
