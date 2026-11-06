// JSON null in both modes (#84). By default null (Typst's `none`) at a
// value position counts as the key being absent: no type error, no
// recursion, a required key holding it is missing, a null trigger does
// not fire, and coerce drops it. With `strict-null: true` null is an
// ordinary value: null-type and nullable(X) take it, every other kind
// rejects it with `type`, and only a missing key is missing. Unknown
// keys are flagged either way, so a typo can't hide behind a null.

#import "../lib.typ": (
  validate, coerce, parse, str-type, content-type, number-type, null-type,
  array-of, object, nullable, any-of, one-of, enum-of, resume-schema,
  resume-schema-strict,
)

#let codes(errs) = errs.map(e => (e.path, e.code))

#let person = object((name: str-type, age: number-type))
#let field(s) = object((f: s))
#let free-form = object((:), additional: true)
#let free = (a: none, b: (c: none))

// ---- the table ---------------------------------------------------------
//
// Each row: a schema, a value, then per mode (default, strict-null) the
// (path, code) of every error validate reports and the model coerce
// builds, which parse returns too where the value is valid and a
// dictionary. A model of `none` is not checked: coerce panics there
// (tests/panics/).

#for (schema, value, default, strict) in (
  // Null at a leaf, an array or an object.
  (field(str-type), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (field(content-type), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (field(number-type), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (
    field(array-of(str-type)),
    (f: none),
    ((), (:)),
    (
      ((("f",), "type"),),
      none,
    ),
  ),
  (field(person), (f: none), ((), (:)), (((("f",), "type"),), none)),
  // Null keys of an object.
  (
    person,
    (name: "Alice", age: none),
    ((), (name: "Alice")),
    (
      ((("age",), "type"),),
      none,
    ),
  ),
  (
    person,
    (name: none, age: none),
    ((), (:)),
    (
      ((("name",), "type"), (("age",), "type")),
      none,
    ),
  ),
  // An unknown key holding null is still unknown.
  (
    person,
    (foo: none),
    (((("foo",), "unknown-key"),), (:)),
    (
      ((("foo",), "unknown-key"),),
      (:),
    ),
  ),
  // Required: null is missing by default, a wrong type in strict mode.
  (
    object((name: str-type), required-keys: ("name",)),
    (:),
    (((("name",), "required"),), (:)),
    (((("name",), "required"),), (:)),
  ),
  (
    object((name: str-type), required-keys: ("name",)),
    (name: none),
    (((("name",), "required"),), (:)),
    (((("name",), "type"),), none),
  ),
  (
    object((name: str-type, age: str-type)),
    (name: none, age: "3"),
    ((), (age: "3")),
    (((("name",), "type"),), none),
  ),
  // nullable(X): dropped by default, kept in strict mode.
  (
    object((name: nullable(str-type)), required-keys: ("name",)),
    (name: none),
    (((("name",), "required"),), (:)),
    ((), (name: none)),
  ),
  (
    object((name: nullable(str-type)), required-keys: ("name",)),
    (name: "a"),
    ((), (name: "a")),
    ((), (name: "a")),
  ),
  (
    object((name: nullable(str-type))),
    (name: none),
    ((), (:)),
    (
      (),
      (name: none),
    ),
  ),
  // Null array elements: dropped by default, judged in strict mode.
  (
    array-of(str-type),
    ("a", none, "c"),
    ((), ("a", "c")),
    (
      (((1,), "type"),),
      none,
    ),
  ),
  (
    array-of(str-type),
    (none, none),
    ((), ()),
    (
      (((0,), "type"), ((1,), "type")),
      none,
    ),
  ),
  (
    array-of(object((name: str-type, position: str-type))),
    (
      (name: "Acme", position: "Engineer"),
      none,
      (name: "Globex", position: "PM"),
    ),
    (
      (),
      ((name: "Acme", position: "Engineer"), (name: "Globex", position: "PM")),
    ),
    (
      (((1,), "type"),),
      none,
    ),
  ),
  // A nullable element counts for the array's rows in strict mode only.
  (
    (..array-of(nullable(str-type)), min-items: 2, unique-items: true),
    ("a", none),
    ((((), "items"),), ("a",)),
    ((), ("a", none)),
  ),
  (
    (..array-of(nullable(str-type)), min-items: 2, unique-items: true),
    (none, "a", "b", none),
    ((), ("a", "b")),
    ((((), "unique"),), (none, "a", "b", none)),
  ),
  // A null dependent trigger fires in strict mode only.
  (
    object(
      (a: nullable(str-type), b: str-type),
      dependent-required: (
        a: ("b",),
      ),
    ),
    (a: none),
    ((), (:)),
    ((((), "dependent"),), (a: none)),
  ),
  // A free-form object (no fields, `additional: true`, like JSON
  // Resume's `custom`) passes through as given, nulls included.
  (free-form, free, ((), free), ((), free)),
  (free-form, (:), ((), (:)), ((), (:))),
  // A union: a non-nullable one judges a null only in strict mode; a
  // nullable one takes it.
  (
    field(any-of((str-type, enum-of((1,))))),
    (f: none),
    ((), (:)),
    (
      ((("f",), "type"),),
      none,
    ),
  ),
  (field(null-type), (f: none), ((), (:)), ((), (f: none))),
  (
    field(one-of((str-type, null-type))),
    (f: none),
    ((), (:)),
    (
      (),
      (f: none),
    ),
  ),
) {
  for (strict, (want, model)) in ((false, default), (true, strict)) {
    let label = repr(value) + " (strict-null: " + repr(strict) + ")"
    assert.eq(
      codes(validate(value, schema: schema, strict-null: strict)),
      want,
      message: label,
    )
    if model != none {
      assert.eq(
        coerce(value, schema: schema, strict-null: strict),
        model,
        message: label,
      )
      if want == () and type(value) == dictionary {
        assert.eq(parse(value, schema: schema, strict-null: strict), model)
      }
    }
  }
}

// A strict-mode null names itself in the error.
#let strict-req = validate(
  (name: none),
  schema: object((name: str-type), required-keys: ("name",)),
  strict-null: true,
)
#assert.eq(strict-req.at(0).message, "expected string, got null.")
#assert.eq(strict-req.at(0).got, "null")
#assert.eq(
  validate(
    (f: none),
    schema: field(any-of((str-type, enum-of((1,))))),
    strict-null: true,
  )
    .at(0)
    .got,
  "null",
)
#assert.eq(
  validate(
    (none, "a", "b", none),
    schema: (..array-of(nullable(str-type)), unique-items: true),
    strict-null: true,
  )
    .at(0)
    .got,
  (0, 3),
)

// A null section of a document is absent too.
#assert.eq(validate((basics: none)), ())
// An empty document is valid; only a null one panics
// (tests/panics/).
#assert.eq(validate((:)), ())

// ---- the union rule: null-type never competes for a non-null value ---

#for strict in (false, true) {
  let wrapped = validate(
    (name: 1),
    schema: object((name: nullable(str-type))),
    strict-null: strict,
  )
  assert.eq(wrapped, validate((name: 1), schema: object((name: str-type))))
  assert.eq(wrapped.at(0).message, "expected string, got integer.")
  // Several non-null members: the summary names only them.
  assert.eq(
    validate(
      true,
      schema: any-of((str-type, enum-of((1,)), null-type)),
      strict-null: strict,
    ),
    validate(true, schema: any-of((str-type, enum-of((1,))))),
  )
  // null-type rejects anything else.
  assert.eq(
    validate(1, schema: null-type, strict-null: strict).at(0).message,
    "expected null, got integer.",
  )
}
// A union of null-type alone still judges a non-null value.
#assert.eq(
  codes(validate(1, schema: any-of((null-type,)), strict-null: true)),
  (((), "type"),),
)

// ---- only `none` is absent ------------------------------------------
//
// An object whose every key is null, or that is empty, or whose keys
// are all unknown, is present: validate counts it, so the model keeps
// an (empty) dict.

#let section = object((name: str-type, summary: content-type))
#assert.eq(coerce((name: none, summary: none), schema: section), (:))
#assert.eq(coerce((:), schema: section), (:))
#assert.eq(coerce((nickname: "Al", color: "blue"), schema: section), (:))
#assert.eq(
  coerce(
    (basics: (name: none, email: none, summary: none)),
    schema: resume-schema-strict,
  ),
  (basics: (:)),
)
#assert.eq(parse(bytes("{}")), (:))
#assert.eq(parse(bytes("{\"basics\":{\"name\":null}}")), (basics: (:)))

// A required key holding `{}` validates, so it survives coercion.
#let holder = object((cfg: object((x: str-type))), required-keys: ("cfg",))
#assert.eq(validate((cfg: (:)), schema: holder), ())
#assert.eq(coerce((cfg: (:)), schema: holder), (cfg: (:)))

// Null content elements drop; the rest still wrap.
#let chs = coerce(
  (none, "first", none, "second"),
  schema: array-of(
    content-type,
  ),
)
#assert.eq(chs.map(type), (content, content))

// ---- array rows count the model --------------------------------------
//
// coerce drops null elements, so min-items and unique-items judge what
// the model will hold, while the duplicate report cites the original
// indices.

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
#assert.eq(
  validate((us: ((x: "a", y: none), (x: "b"))), schema: object((us: unique))),
  (),
)
// Items that differ only by a null key are duplicates, nested too.
#let null-dupes = ((x: "a", y: none), (x: "a"))
#assert.eq(coerce(null-dupes, schema: unique), ((x: "a"), (x: "a")))
#let dupe-errs = validate((us: null-dupes), schema: object((us: unique)))
#assert.eq(dupe-errs.len(), 1)
#assert(dupe-errs.at(0).message.contains("indices 0 and 1"))
#assert.eq(
  validate(((y: (z: none)), (y: (:))), schema: (
    ..array-of(object((y: object((z: str-type))))),
    unique-items: true,
  )).len(),
  1,
)

// ---- end to end ---------------------------------------------------------

// A resume with nulls at every shape (leaf, array, array element, whole
// section) validates cleanly, and the model leaves them out.
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
  custom: (myTool: none),
)
#assert.eq(validate(raw), ())
// resume-schema-strict, so highlights coerce to content.
#let model = coerce(raw, schema: resume-schema-strict)
#assert.eq(model.basics, (name: "Alice"))
#assert.eq(model.work.at(0).keys(), ("name", "position", "highlights"))
#assert.eq(model.work.at(0).highlights.map(type), (content, content))
#assert("skills" not in model)
#assert("meta" not in model)
// Except inside the free-form `custom` bag, which keeps its nulls.
#assert.eq(model.custom, (myTool: none))
