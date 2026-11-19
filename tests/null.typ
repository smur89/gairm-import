// JSON null in both modes (#84). By default null (Typst's `none`) at a
// value position counts as the key being absent: no type error, no
// recursion, a required key holding it is missing, a null trigger does
// not fire, and coerce drops it. With `strict-null: true` null is an
// ordinary value: null() and nullable(X) take it, every other kind
// rejects it with `type`, and only a missing key is missing. Unknown
// keys are flagged either way, so a typo can't hide behind a null.

#import "../lib.typ": (
  validate, coerce, parse, markup, null, array-of, object, nullable, any-of,
  one-of, if-of, enum-of, string, number,
)
#import "fixtures/resume.typ": resume-schema, resume-schema-strict

#let codes(errs) = errs.map(e => (e.path, e.code))

#let person = object((name: string(), age: number()))
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
  (field(string()), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (field(markup()), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (field(number()), (f: none), ((), (:)), (((("f",), "type"),), none)),
  (
    field(array-of(string())),
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
    object((name: string()), required-keys: ("name",)),
    (:),
    (((("name",), "required"),), (:)),
    (((("name",), "required"),), (:)),
  ),
  (
    object((name: string()), required-keys: ("name",)),
    (name: none),
    (((("name",), "required"),), (:)),
    (((("name",), "type"),), none),
  ),
  (
    object((name: string(), age: string())),
    (name: none, age: "3"),
    ((), (age: "3")),
    (((("name",), "type"),), none),
  ),
  // nullable(X): dropped by default, kept in strict mode.
  (
    object((name: nullable(string())), required-keys: ("name",)),
    (name: none),
    (((("name",), "required"),), (:)),
    ((), (name: none)),
  ),
  (
    object((name: nullable(string())), required-keys: ("name",)),
    (name: "a"),
    ((), (name: "a")),
    ((), (name: "a")),
  ),
  (
    object((name: nullable(string()))),
    (name: none),
    ((), (:)),
    (
      (),
      (name: none),
    ),
  ),
  // Null array elements: dropped by default, judged in strict mode.
  (
    array-of(string()),
    ("a", none, "c"),
    ((), ("a", "c")),
    (
      (((1,), "type"),),
      none,
    ),
  ),
  (
    array-of(string()),
    (none, none),
    ((), ()),
    (
      (((0,), "type"), ((1,), "type")),
      none,
    ),
  ),
  (
    array-of(object((name: string(), position: string()))),
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
    (..array-of(nullable(string())), min-items: 2, unique-items: true),
    ("a", none),
    ((((), "items"),), ("a",)),
    ((), ("a", none)),
  ),
  (
    (..array-of(nullable(string())), min-items: 2, unique-items: true),
    (none, "a", "b", none),
    ((), ("a", "b")),
    ((((), "unique"),), (none, "a", "b", none)),
  ),
  // A null dependent trigger fires in strict mode only.
  (
    object(
      (a: nullable(string()), b: string()),
      dependent-required: (
        a: ("b",),
      ),
    ),
    (a: none),
    ((), (:)),
    (((("b",), "dependent"),), (a: none)),
  ),
  // A free-form object (no fields, `additional: true`, like JSON
  // Resume's `custom`) passes through as given, nulls included.
  (free-form, free, ((), free), ((), free)),
  (free-form, (:), ((), (:)), ((), (:))),
  // A union: a non-nullable one judges a null only in strict mode; a
  // nullable one takes it.
  (
    field(any-of((string(), enum-of((1,))))),
    (f: none),
    ((), (:)),
    (
      ((("f",), "type"),),
      none,
    ),
  ),
  (field(null()), (f: none), ((), (:)), ((), (f: none))),
  (
    field(one-of((string(), null()))),
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
      codes(validate(schema, value, strict-null: strict)),
      want,
      message: label,
    )
    if model != none {
      assert.eq(
        coerce(schema, value, strict-null: strict),
        model,
        message: label,
      )
      if want == () and type(value) == dictionary {
        assert.eq(parse(schema, value, strict-null: strict), model)
      }
    }
  }
}

// A strict-mode null names itself in the error.
#let strict-req = validate(
  object((name: string()), required-keys: ("name",)),
  (name: none),
  strict-null: true,
)
#assert.eq(strict-req.at(0).message, "expected string, got null.")
#assert.eq(strict-req.at(0).got, "null")
#assert.eq(
  validate(
    field(any-of((string(), enum-of((1,))))),
    (f: none),
    strict-null: true,
  )
    .at(0)
    .got,
  "null",
)
#assert.eq(
  validate(
    (..array-of(nullable(string())), unique-items: true),
    (none, "a", "b", none),
    strict-null: true,
  )
    .at(0)
    .got,
  (0, 3),
)

// A null section of a document is absent too.
#assert.eq(validate(resume-schema, (basics: none)), ())
// An empty document is valid; only a null one panics
// (tests/panics/).
#assert.eq(validate(resume-schema, (:)), ())

// ---- the union rule: null() never competes for a non-null value ---

#for strict in (false, true) {
  let wrapped = validate(
    object((name: nullable(string()))),
    (name: 1),
    strict-null: strict,
  )
  assert.eq(wrapped, validate(object((name: string())), (name: 1)))
  assert.eq(wrapped.at(0).message, "expected string, got integer.")
  // Several non-null members: the summary names only them.
  assert.eq(
    validate(
      any-of((string(), enum-of((1,)), null())),
      true,
      strict-null: strict,
    ),
    validate(any-of((string(), enum-of((1,)))), true),
  )
  // null() rejects anything else.
  assert.eq(
    validate(null(), 1, strict-null: strict).at(0).message,
    "expected null, got integer.",
  )
}
// A union of null() alone still judges a non-null value.
#assert.eq(
  codes(validate(any-of((null(),)), 1, strict-null: true)),
  (((), "type"),),
)

// ---- a conditional judges null in the walk's mode -------------------
//
// The condition and the branch see the same null: absent by default,
// so no branch runs; a value with strict-null, so the condition picks
// the branch for it.

#let null-or-word = field(if-of(
  null(),
  then: null(),
  otherwise: (..string(), min-length: 2),
))
#let null-if-str = field(if-of(
  string(),
  then: string(),
  otherwise: number(),
))
#for schema in (null-or-word, null-if-str) {
  assert.eq(validate(schema, (f: none)), ())
  assert.eq(coerce(schema, (f: none)), (:))
}
#assert.eq(validate(null-or-word, (f: none), strict-null: true), ())
#assert.eq(coerce(null-or-word, (f: none), strict-null: true), (
  f: none,
))
#assert.eq(
  codes(validate(null-or-word, (f: "a"), strict-null: true)),
  ((("f",), "length"),),
)
#assert.eq(
  validate(null-if-str, (f: none), strict-null: true).map(e => (
    e.code,
    e.message,
  )),
  (("type", "expected number, got null."),),
)

// ---- only `none` is absent ------------------------------------------
//
// An object whose every key is null, or that is empty, or whose keys
// are all unknown, is present: validate counts it, so the model keeps
// an (empty) dict.

#let section = object((name: string(), summary: markup()))
#assert.eq(coerce(section, (name: none, summary: none)), (:))
#assert.eq(coerce(section, (:)), (:))
#assert.eq(coerce(section, (nickname: "Al", color: "blue")), (:))
#assert.eq(
  coerce(resume-schema-strict, (
    basics: (name: none, email: none, summary: none),
  )),
  (basics: (:)),
)
#assert.eq(parse(resume-schema, bytes("{}")), (:))
#assert.eq(
  parse(resume-schema, bytes("{\"basics\":{\"name\":null}}")),
  (basics: (:)),
)

// A required key holding `{}` validates, so it survives coercion.
#let holder = object((cfg: object((x: string()))), required-keys: ("cfg",))
#assert.eq(validate(holder, (cfg: (:))), ())
#assert.eq(coerce(holder, (cfg: (:))), (cfg: (:)))

// Null content elements drop; the rest still wrap.
#let chs = coerce(
  array-of(
    markup(),
  ),
  (none, "first", none, "second"),
)
#assert.eq(chs.map(type), (content, content))

// ---- array rows count the model --------------------------------------
//
// coerce drops null elements, so min-items and unique-items judge what
// the model will hold, while the duplicate report cites the original
// indices.

#let at-least-one = (..array-of(object((y: string()))), min-items: 1)
#assert.eq(validate(object((ys: at-least-one)), (ys: ((y: none),))), ())
#assert.eq(coerce(at-least-one, ((y: none),)), ((:),))

#let unique = (
  ..array-of(object((x: string(), y: object((:))))),
  unique-items: true,
)
#let distinct = ((x: "a", y: (:)), (x: "a"))
#assert.eq(validate(object((us: unique)), (us: distinct)), ())
#assert.eq(coerce(unique, distinct), distinct)
#assert.eq(
  validate(object((us: unique)), (us: ((x: "a", y: none), (x: "b")))),
  (),
)
// Items that differ only by a null key are duplicates, nested too.
#let null-dupes = ((x: "a", y: none), (x: "a"))
#assert.eq(coerce(unique, null-dupes), ((x: "a"), (x: "a")))
#let dupe-errs = validate(object((us: unique)), (us: null-dupes))
#assert.eq(dupe-errs.len(), 1)
#assert(dupe-errs.at(0).message.contains("indices 0 and 1"))
#assert.eq(
  validate(
    (
      ..array-of(object((y: object((z: string()))))),
      unique-items: true,
    ),
    ((y: (z: none)), (y: (:))),
  ).len(),
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
#assert.eq(validate(resume-schema, raw), ())
// resume-schema-strict, so highlights coerce to content.
#let model = coerce(resume-schema-strict, raw)
#assert.eq(model.basics, (name: "Alice"))
#assert.eq(model.work.at(0).keys(), ("name", "position", "highlights"))
#assert.eq(model.work.at(0).highlights.map(type), (content, content))
#assert("skills" not in model)
#assert("meta" not in model)
// Except inside the free-form `custom` bag, which keeps its nulls.
#assert.eq(model.custom, (myTool: none))
