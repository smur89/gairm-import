// _coerce drops JSON null (Typst's `none`) at any value position so
// downstream renderers see "key not in dict" rather than a stray
// `none` value to special-case. This mirrors the validate-side
// policy in tests/validate_null_handling.typ.

#import "../lib.typ": coerce-resume
#import "../internal/coerce.typ": _coerce
#import "../internal/schema.typ": str-type, content-type, number-type, array-of, object

// Null at a primitive value position coerces to `none` so the parent
// filter can drop it.
#assert.eq(_coerce(str-type, none), none)
#assert.eq(_coerce(content-type, none), none)
#assert.eq(_coerce(number-type, none), none)
#assert.eq(_coerce(array-of(str-type), none), none)
#assert.eq(_coerce(object((name: str-type)), none), none)

// Null elements inside an array are dropped from the coerced output.
#assert.eq(_coerce(array-of(str-type), ("a", none, "c")), ("a", "c"))
#assert.eq(_coerce(array-of(str-type), (none, none)), ())

#let chs = _coerce(array-of(content-type), (none, "first", none, "second"))
#assert.eq(chs.len(), 2)
#assert.eq(type(chs.at(0)), content)
#assert.eq(type(chs.at(1)), content)

// Per-key null inside an object is filtered out — the coerced dict
// does not carry the key at all.
#let person = object((name: str-type, age: number-type, summary: content-type))
#let coerced = _coerce(person, (name: "Alice", age: none, summary: none))
#assert.eq(coerced.keys(), ("name",))
#assert.eq(coerced.name, "Alice")
#assert("age" not in coerced)
#assert("summary" not in coerced)

// End-to-end against the canonical schema: nulls scattered through
// the input are absent from the coerced model.
#let raw = (
  basics: (
    name: "Alice",
    summary: none,
    email: none,
    location: none,
    profiles: none,
  ),
  work: (
    (
      name: "Acme",
      position: "Engineer",
      endDate: none,
      summary: none,
      highlights: ("led the migration", none, "shipped v2"),
    ),
  ),
  skills: none,
  meta: none,
)
#let model = coerce-resume(raw)

#assert.eq(model.basics.name, "Alice")
#assert("summary" not in model.basics)
#assert("email" not in model.basics)
#assert("location" not in model.basics)
#assert("profiles" not in model.basics)

#assert.eq(model.work.at(0).name, "Acme")
#assert.eq(model.work.at(0).position, "Engineer")
#assert("endDate" not in model.work.at(0))
#assert("summary" not in model.work.at(0))

// Null elements are dropped from inside arrays.
#assert.eq(model.work.at(0).highlights.len(), 2)
#assert.eq(type(model.work.at(0).highlights.at(0)), content)
#assert.eq(type(model.work.at(0).highlights.at(1)), content)

// Whole-section nulls disappear from the top-level model.
#assert("skills" not in model)
#assert("meta" not in model)
