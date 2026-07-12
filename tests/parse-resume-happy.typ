// End-to-end: minimal valid resume passes through validate + coerce
// via every supported entry shape (dict, path value, string path).

#import "../lib.typ": validate, coerce, parse, resume-schema-strict

// Path-string entry against the default schema: parse reads the file
// via json() and runs the full pipeline. summary stays str because
// the faithful resume-schema doesn't wrap free-text fields.
#let from-path = parse("/tests/fixtures/resume-minimal.json")
#assert.eq(type(from-path), dictionary)
#assert.eq(from-path.basics.name, "Seán Ó Murchú")
#assert.eq(type(from-path.basics.summary), str)

// path() entry: resolves against the caller's .typ, not @preview.
#let from-path-value = parse(path("fixtures/resume-minimal.json"))
#assert.eq(from-path-value.basics.name, from-path.basics.name)

// resume-schema-strict opts into content wrapping for the renderer
// ergonomics — summary is content there.
#let from-strict = parse(
  "/tests/fixtures/resume-minimal.json",
  schema: resume-schema-strict,
)
#assert.eq(type(from-strict.basics.summary), content)

// Dict entry: same model, parsing done by the caller. Exercises
// validate + coerce independently against the same fixture.
#let raw = json("fixtures/resume-minimal.json")
#assert.eq(validate(raw), ())
#let from-dict = coerce(raw)
#assert.eq(from-dict.basics.name, from-path.basics.name)
#assert.eq(parse(raw).basics.name, from-path.basics.name)
