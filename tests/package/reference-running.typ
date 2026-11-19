// Mirrors REFERENCE.md, "Running": the calling convention, the error
// record, and each row of "The model". The schemas and documents are
// ours.
#import "@preview/gairm-import:0.0.0": *

// The schema first; .with binds it.
#let s = object((url: string(format: "uri")))
#assert.eq(parse.with(s)((url: "https://x.example")), (
  url: "https://x.example",
))

// An error record and its pointer.
#let work = object((work: array-of(s)))
#let r = validate(work, (work: ((url: "nope"),))).first()
#assert.eq(r.keys(), ("path", "code", "message", "expected", "got"))
#assert.eq(r.path, ("work", 0, "url"))
#assert.eq(path-to-pointer(r.path), "/work/0/url")
#assert.eq(r.message, "expected a URI (e.g. \"https://example.com\").")
#assert.eq(validate(work, (:)), ())

// Error records: a dependent record's path, expected and got; a
// one-of's expected; a key that is not a plain name in a rendered path.
#let dep = validate(
  object(
    (card: string(), billing: string()),
    dependent-required: (card: ("billing",)),
  ),
  (card: "x"),
).first()
#assert.eq(dep.path, ("billing",))
#assert.eq(dep.expected, (dependent-required: (card: ("billing",))))
#assert.eq(dep.got, none)
#assert.eq(
  validate(one-of(number(), integer()), 1).first().expected,
  ("number", "integer"),
)
#assert.eq(
  format-errors(validate(object(("a.b": object((c: string())))), (
    "a.b": (c: 1),
  ))),
  "gairm-import: found 1 problem in the input:\n  - [\"a.b\"].c: expected string, got integer.",
)

// The model, row by row.
#assert.eq(
  coerce(string(format: "date"), datetime(year: 2024, month: 1, day: 5)),
  "2024-01-05",
)
#assert.eq(coerce(markup(), "hi"), [hi])
#assert.eq(type(coerce(integer(), 1.0)), float)
#assert.eq(coerce(enum-of((1, "a")), "a"), "a")
#assert.eq(coerce(unknown(), (a: (b: none))), (a: (b: none)))
#assert.eq(coerce(array-of(string()), ("a", none, "b")), ("a", "b"))
#assert.eq(coerce(object((a: string())), (a: "x", b: 1)), (a: "x"))
#assert.eq(
  coerce(object((a: string()), additional: true), (a: "x", b: (c: none))),
  (a: "x", b: (c: none)),
)
#assert.eq(
  coerce(object((:), additional: markup()), (a: "x")),
  (a: [x]),
)
#assert.eq(coerce(object((:), additional: true), (a: none)), (a: none))
#assert.eq(coerce(any-of(markup(), string()), "x"), [x])
#assert.eq(coerce(not-of(number()), "x"), "x")
#assert.eq(
  coerce(if-of(string(), then: markup()), "x"),
  [x],
)
#assert.eq(coerce(if-of(string(), then: markup()), 3), 3)
