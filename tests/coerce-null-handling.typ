// _coerce drops JSON null (Typst's `none`) at any value position so
// downstream renderers see "key not in dict" rather than a stray
// `none` value to special-case. This mirrors the validate-side
// policy in tests/validate-null-handling.typ.

#import "../lib.typ": coerce, parse, validate, resume-schema-strict
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

// Exception: a free-form bag (no fields, `additional: true`, like JSON
// Resume's `custom`) passes through untouched — nulls and emptiness
// included — even when it sits inside a section that drops nulls.
#let bag = object((:), additional: true)
#assert.eq(_coerce(bag, (a: none, b: (c: none))), (a: none, b: (c: none)))
#assert.eq(_coerce(bag, (:)), (:))
#assert.eq(
  coerce(
    (basics: (name: "J"), custom: (myTool: none)),
    schema: resume-schema-strict,
  ).custom,
  (myTool: none),
)

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

// Only `none` is absent: an object whose every key is null, or an
// empty object, stays an (empty) dict. Validate counts it as present,
// so the model must too.
#assert.eq(_coerce(person, (name: none, age: none, summary: none)), (:))
#assert.eq(_coerce(person, (:)), (:))

// Unknown keys are dropped, leaving an empty dict, not `none`.
#assert.eq(_coerce(person, (nickname: "Al", color: "blue")), (:))

// Recursively: an all-null nested object stays as an empty section,
// and an empty document stays an empty dict.
#let all-null-basics = coerce(
  (basics: (name: none, email: none, summary: none)),
  schema: resume-schema-strict,
)
#assert.eq(all-null-basics, (basics: (:)))
#assert.eq(parse(bytes("{}")), (:))
#assert.eq(parse(bytes("{\"basics\":{\"name\":null}}")), (basics: (:)))

// A required key holding `{}` validates, so it must survive coercion.
#let holder = object((cfg: object((x: str-type))), required-keys: ("cfg",))
#assert.eq(validate((cfg: (:)), schema: holder), ())
#assert.eq(coerce((cfg: (:)), schema: holder), (cfg: (:)))

// Array constraints: the coerced model keeps what validate counted.
#let at-least-one = (..array-of(object((y: str-type))), min-items: 1)
#assert.eq(validate((ys: ((y: none),)), schema: object((ys: at-least-one))), ())
#assert.eq(_coerce(at-least-one, ((y: none),)), ((:),))
#let unique = (
  ..array-of(object((x: str-type, y: object((:))))),
  unique-items: true,
)
#let distinct = ((x: "a", y: (:)), (x: "a"))
#assert.eq(validate((us: distinct), schema: object((us: unique))), ())
#assert.eq(_coerce(unique, distinct), distinct)

// And a single live leaf anywhere keeps the chain intact.
#let one-leaf = coerce(
  (basics: (name: "Alice", email: none)),
  schema: resume-schema-strict,
)
#assert.eq(one-leaf.basics.name, "Alice")
#assert("email" not in one-leaf.basics)
