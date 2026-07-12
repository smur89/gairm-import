// _coerce drops JSON null (Typst's `none`) at any value position so
// downstream renderers see "key not in dict" rather than a stray
// `none` value to special-case. This mirrors the validate-side
// policy in tests/validate-null-handling.typ.

#import "../lib.typ": coerce, resume-schema-strict
#import "../internal/coerce.typ": _coerce
#import "../internal/kinds.typ": (
  str-type, content-type, number-type, array-of, object,
)

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

// Null elements inside an array of objects are dropped wholesale — the
// surviving objects keep their full shape.
#let work-item = object((name: str-type, position: str-type))
#let work-coerced = _coerce(
  array-of(work-item),
  (
    (name: "Acme", position: "Engineer"),
    none,
    (name: "Globex", position: "PM"),
  ),
)
#assert.eq(work-coerced.len(), 2)
#assert.eq(work-coerced.at(0), (name: "Acme", position: "Engineer"))
#assert.eq(work-coerced.at(1), (name: "Globex", position: "PM"))

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
// resume-schema-strict so highlights coerce to content — exercises
// the null-filter under a non-trivial element kind.
#let model = coerce(raw, schema: resume-schema-strict)

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

// An object whose every key is null coerces to `none` — symmetric
// with the leaf-null policy. The parent filter then drops the key.
#assert.eq(_coerce(person, (name: none, age: none, summary: none)), none)
#assert.eq(_coerce(person, (:)), none)

// Unknown keys are dropped, so an object with only unknown keys is
// also all-empty after the shape filter and becomes `none`.
#assert.eq(_coerce(person, (nickname: "Al", color: "blue")), none)

// Recursively: an all-null nested object propagates outward. A
// top-level resume whose only present section is itself all-null
// coerces to `none` (consistent extension of the policy — every key
// in the root coerced to absent, so the root is absent too).
#let all-null-basics = coerce(
  (basics: (name: none, email: none, summary: none)),
  schema: resume-schema-strict,
)
#assert.eq(all-null-basics, none)

// And a single live leaf anywhere keeps the chain intact.
#let one-leaf = coerce(
  (basics: (name: "Alice", email: none)),
  schema: resume-schema-strict,
)
#assert.eq(one-leaf.basics.name, "Alice")
#assert("email" not in one-leaf.basics)
