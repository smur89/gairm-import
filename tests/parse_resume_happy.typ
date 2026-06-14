// End-to-end: minimal valid resume passes through validate + coerce.

#import "../lib.typ": read-resume, validate-resume, coerce-resume, parse-resume

#let raw = read-resume("/tests/fixtures/resume_minimal.json")

#assert.eq(validate-resume(raw), ())

#let model = coerce-resume(raw)
#assert.eq(type(model), dictionary)
#assert.eq(model.basics.name, "Seán Ó Murchú")
#assert.eq(type(model.basics.summary), content)

#let model2 = parse-resume(raw)
#assert.eq(model.basics.name, model2.basics.name)
