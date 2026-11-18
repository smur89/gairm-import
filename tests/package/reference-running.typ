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

// The model, row by row.
#assert.eq(
  coerce(string(format: "date"), datetime(year: 2024, month: 1, day: 5)),
  "2024-01-05",
)
#assert.eq(coerce(content-type, "hi"), [hi])
#assert.eq(type(coerce(integer(), 1.0)), float)
#assert.eq(coerce(enum-of((1, "a")), "a"), "a")
#assert.eq(coerce(any-type, (a: (b: none))), (a: (b: none)))
#assert.eq(coerce(array-of(string()), ("a", none, "b")), ("a", "b"))
#assert.eq(coerce(object((a: string())), (a: "x", b: 1)), (a: "x"))
#assert.eq(
  coerce(object((a: string()), additional: true), (a: "x", b: (c: none))),
  (a: "x", b: (c: none)),
)
#assert.eq(
  coerce(object((:), additional: content-type), (a: "x")),
  (a: [x]),
)
#assert.eq(coerce(object((:), additional: true), (a: none)), (a: none))
#assert.eq(coerce(any-of(content-type, string()), "x"), [x])
#assert.eq(coerce(not-of(number()), "x"), "x")
#assert.eq(
  coerce(if-of(string(), then: content-type), "x"),
  [x],
)
#assert.eq(coerce(if-of(string(), then: content-type), 3), 3)

// paths-of-kind: a constructor finds the nodes it builds.
#let u = object((
  a: any-of(string(), number()),
  b: one-of(string(), number()),
  c: nullable(string()),
  d: const-of("x"),
  e: enum-of(("x", "y")),
))
#assert.eq(paths-of-kind(u, any-of), (("a",), ("c",)))
#assert.eq(paths-of-kind(u, one-of), (("b",),))
#assert.eq(paths-of-kind(u, nullable), (("c",),))
#assert.eq(paths-of-kind(u, const-of), (("d",),))
#assert.eq(paths-of-kind(u, enum-of), (("d",), ("e",)))
