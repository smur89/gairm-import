// _validate treats JSON null (Typst's `none`) as "key absent" at any
// value position — no type error, no recursion. Per-key null values
// inside objects are skipped; null array elements are absorbed; an
// entire-section null is treated as if the section were omitted.
// Unknown keys are still flagged even when their value is null,
// because silently swallowing typos would defeat strict validation.

#import "../lib.typ": validate
#import "../internal/validate.typ": _validate
#import "../lib.typ": str-type, content-type, number-type, array-of, object

// Null at a primitive value position: no error.
#assert.eq(_validate(str-type, none, ("basics", "summary")), ())
#assert.eq(_validate(content-type, none, ("basics", "summary")), ())
#assert.eq(_validate(number-type, none, ("rating",)), ())

// Null where an array is expected: treated as absent, no error.
#assert.eq(_validate(array-of(str-type), none, ("keywords",)), ())

// Null elements inside an array: silently dropped from the error walk.
#assert.eq(_validate(array-of(str-type), ("a", none, "c"), ("keywords",)), ())
#assert.eq(
  _validate(array-of(content-type), (none, "one", none), ("highlights",)),
  (),
)

// Null elements inside an array of objects: each null element is treated
// as "key absent" by the per-element early return, so the walk produces
// no errors even when the live siblings would otherwise be required to
// conform to the inner object shape.
#let work-item = object((name: str-type, position: str-type))
#assert.eq(
  _validate(
    array-of(work-item),
    (
      (name: "Acme", position: "Engineer"),
      none,
      (name: "Globex", position: "Engineer"),
    ),
    ("work",),
  ),
  (),
)

// Null where an object is expected: treated as absent.
#let person = object((name: str-type, age: number-type))
#assert.eq(_validate(person, none, ("basics",)), ())

// Per-key null inside an object: skipped, no error.
#assert.eq(validate((name: "Alice", age: none), schema: person), ())
#assert.eq(validate((name: none, age: none), schema: person), ())

// Unknown key with a null value still errors — typos must not slip
// through just because the user wrote `null`.
#let errs-unknown = _validate(person, (foo: none), ("basics",))
#assert.eq(errs-unknown.len(), 1)
#assert.eq(errs-unknown.at(0).path, ("basics", "foo"))
#assert(errs-unknown.at(0).message.contains("unknown key"))

// Required key with explicit null still flagged as missing — null-as-
// absent applies uniformly.
#let strict = object(
  (title: str-type, body: content-type),
  required-keys: ("title", "body"),
)
#let errs-required = validate((title: "hi", body: none), schema: strict)
#assert.eq(errs-required.len(), 1)
#assert.eq(errs-required.at(0).path, ("body",))
#assert(errs-required.at(0).message.contains("missing required key"))

// End-to-end against the real canonical schema: a resume sprinkled
// with nulls at every shape (primitive leaf, array container, array
// element, whole section) validates cleanly.
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
#assert.eq(validate(raw), ())

// The engine still treats `none` as "key absent" at any value
// position — that's the right rule for LEAVES inside a document.
// Verified here at the engine level so the wrapper can layer its
// own root-level guard on top without changing the leaf rule.
#import "../lib.typ": resume-schema
#import "../internal/validate.typ": _validate
#assert.eq(_validate(resume-schema, none, ()), ())

// Public wrappers reject a null root explicitly so callers passing
// the wrong thing get a friendly panic, not silent garbage. We can't
// catch the panic from inside the compiled test (Typst has no
// try/catch), so the panic is exercised by tests/panics/*-null-root.typ.
// The empty-dict input is
// the closest non-panicking sibling — it should still succeed,
// confirming the guard fires only on `none`.
#assert.eq(validate((:)), ())
