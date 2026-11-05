// _coerce drops JSON null (Typst's `none`) at any value position so
// downstream renderers see "key not in dict" rather than a stray
// `none` value to special-case. This mirrors the validate-side
// policy in tests/validate-null-handling.typ.

#import "../lib.typ": coerce, parse, validate, resume-schema-strict
#import "../internal/coerce.typ": _coerce
#import "../lib.typ": str-type, content-type, number-type, array-of, object

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
#assert.eq(coerce((a: none, b: (c: none)), schema: bag), (
  a: none,
  b: (c: none),
))
#assert.eq(coerce((:), schema: bag), (:))
#assert.eq(
  coerce(
    (basics: (name: "J"), custom: (myTool: none)),
    schema: resume-schema-strict,
  ).custom,
  (myTool: none),
)

// Null elements inside an array are dropped from the coerced output.
#assert.eq(coerce(("a", none, "c"), schema: array-of(str-type)), ("a", "c"))
#assert.eq(coerce((none, none), schema: array-of(str-type)), ())

// Null elements inside an array of objects are dropped wholesale — the
// surviving objects keep their full shape.
#let work-item = object((name: str-type, position: str-type))
#let work-coerced = coerce(
  (
    (name: "Acme", position: "Engineer"),
    none,
    (name: "Globex", position: "PM"),
  ),
  schema: array-of(work-item),
)
#assert.eq(work-coerced.len(), 2)
#assert.eq(work-coerced.at(0), (name: "Acme", position: "Engineer"))
#assert.eq(work-coerced.at(1), (name: "Globex", position: "PM"))

#let chs = coerce(
  (none, "first", none, "second"),
  schema: array-of(content-type),
)
#assert.eq(chs.len(), 2)
#assert.eq(type(chs.at(0)), content)
#assert.eq(type(chs.at(1)), content)

// Per-key null inside an object is filtered out — the coerced dict
// does not carry the key at all.
#let person = object((name: str-type, age: number-type, summary: content-type))
#let coerced = coerce((name: "Alice", age: none, summary: none), schema: person)
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
#assert.eq(coerce((name: none, age: none, summary: none), schema: person), (:))
#assert.eq(coerce((:), schema: person), (:))

// Unknown keys are dropped, leaving an empty dict, not `none`.
#assert.eq(coerce((nickname: "Al", color: "blue"), schema: person), (:))

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
#assert.eq(coerce(((y: none),), schema: at-least-one), ((:),))
#let unique = (
  ..array-of(object((x: str-type, y: object((:))))),
  unique-items: true,
)
#let distinct = ((x: "a", y: (:)), (x: "a"))
#assert.eq(validate((us: distinct), schema: object((us: unique))), ())
#assert.eq(coerce(distinct, schema: unique), distinct)
// Uniqueness compares items with nulls removed, as coerce will see
// them: these differ only by a null key, so they are duplicates.
#let null-dupes = ((x: "a", y: none), (x: "a"))
#assert.eq(coerce(null-dupes, schema: unique), ((x: "a"), (x: "a")))
#let dupe-errs = validate((us: null-dupes), schema: object((us: unique)))
#assert.eq(dupe-errs.len(), 1)
#assert(dupe-errs.at(0).message.contains("indices 0 and 1"))
// Nested too: a null inside a nested object is stripped before comparing.
#let unique-nested = (
  ..array-of(object((y: object((z: str-type))))),
  unique-items: true,
)
#assert.eq(
  validate(((y: (z: none)), (y: (:))), schema: unique-nested).len(),
  1,
)
#assert.eq(
  validate(
    (us: ((x: "a", y: none), (x: "b"))),
    schema: object((us: unique)),
  ),
  (),
)

// And a single live leaf anywhere keeps the chain intact.
#let one-leaf = coerce(
  (basics: (name: "Alice", email: none)),
  schema: resume-schema-strict,
)
#assert.eq(one-leaf.basics.name, "Alice")
#assert("email" not in one-leaf.basics)
