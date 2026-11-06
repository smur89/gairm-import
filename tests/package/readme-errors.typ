// Mirrors README.md, "Errors": the combined report, the note that the
// default schema reports only its first line, and the record it gives
// for that line. The document is ours; the report text must match the
// README's block (after "panicked with: ").
#import "@preview/gairm-import:0.0.0": (
  validate, format-errors, resume-schema-strict,
)

#let doc = (
  basics: (name: "Ada", email: 1),
  work: ((name: "Acme", positon: "Engineer"),),
  meta: (foo: "bar"),
)

#assert.eq(
  format-errors(validate(doc, schema: resume-schema-strict)),
  "gairm-import: found 3 problems in the input:
  - basics.email: expected string, got integer.
  - work[0].positon: unknown key \"positon\". Did you mean \"position\"?
  - meta.foo: unknown key \"foo\". Valid keys: canonical, version, lastModified.",
)

#assert.eq(
  validate(doc).map(e => e.path),
  (("basics", "email"),),
)

#assert.eq(validate(doc).first(), (
  path: ("basics", "email"),
  code: "type",
  message: "expected string, got integer.",
  expected: "string",
  got: "integer",
))
