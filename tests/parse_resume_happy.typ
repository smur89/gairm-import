// End-to-end: minimal valid resume passes through validate + coerce
// via every supported entry shape (dict, path string).

#import "../lib.typ": validate-resume, coerce-resume, parse-resume

// Path-string entry: parse-resume reads the file via json() and runs
// the full pipeline in one call.
#let from-path = parse-resume("/tests/fixtures/resume_minimal.json")
#assert.eq(type(from-path), dictionary)
#assert.eq(from-path.basics.name, "Seán Ó Murchú")
#assert.eq(type(from-path.basics.summary), content)

// Dict entry: the same model, this time with the parsing done by the
// caller. Exercises validate-resume + coerce-resume independently
// against the same fixture.
#let raw = json("fixtures/resume_minimal.json")
#assert.eq(validate-resume(raw), ())
#let from-dict = coerce-resume(raw)
#assert.eq(from-dict.basics.name, from-path.basics.name)
#assert.eq(parse-resume(raw).basics.name, from-path.basics.name)
