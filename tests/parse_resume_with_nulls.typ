// End-to-end: a real JSON file with explicit `null` values throughout
// validates cleanly and coerces to a model with those keys absent.
// Mirrors the convention used by most JSON Resume emitters, where
// "summary": null is semantically equivalent to omitting the key.

#import "../lib.typ": validate, parse

#let raw = json("fixtures/resume_with_nulls.json")

// No validation errors — null is treated as "key absent".
#assert.eq(validate(raw), ())

#let model = parse(raw)

// Present scalars survive the coercion.
#assert.eq(model.basics.name, "Seán Ó Murchú")
#assert.eq(model.basics.email, "sean@example.com")
#assert.eq(model.work.at(0).name, "Acme Corp")
#assert.eq(model.work.at(0).startDate, "2022-01")

// Null basics fields are absent from the coerced dict.
#assert("phone" not in model.basics)
#assert("url" not in model.basics)
#assert("summary" not in model.basics)
#assert("image" not in model.basics)
#assert("location" not in model.basics)
#assert("profiles" not in model.basics)

// Null work-item fields are absent from the coerced dict.
#assert("endDate" not in model.work.at(0))
#assert("summary" not in model.work.at(0))
#assert("url" not in model.work.at(0))

// Null elements are dropped from inside arrays, but live elements
// survive and are coerced to content.
#assert.eq(model.work.at(0).highlights.len(), 2)
#assert.eq(type(model.work.at(0).highlights.at(0)), content)
#assert.eq(type(model.work.at(0).highlights.at(1)), content)

// A null entry inside an array of objects is dropped wholesale; the
// surviving siblings are intact and indexable in order.
#assert.eq(model.work.len(), 2)
#assert.eq(model.work.at(1).name, "Globex")
#assert.eq(model.work.at(1).position, "Staff Engineer")
#assert.eq(model.work.at(1).startDate, "2018-06")
#assert.eq(model.work.at(1).endDate, "2021-12")

// Whole-section nulls disappear from the top-level model.
#assert("skills" not in model)
#assert("languages" not in model)
#assert("interests" not in model)
#assert("references" not in model)
#assert("projects" not in model)
#assert("volunteer" not in model)
#assert("education" not in model)
#assert("awards" not in model)
#assert("certificates" not in model)
#assert("publications" not in model)
#assert("meta" not in model)
