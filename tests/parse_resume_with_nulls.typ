// A real JSON file with explicit `null` values throughout validates
// cleanly under BOTH schemas and coerces to a model with those keys
// absent. Mirrors the convention used by most JSON Resume emitters,
// where `"summary": null` is semantically equivalent to omitting the
// key.

#import "../lib.typ": validate, parse, resume-schema-strict

#let raw = json("fixtures/resume_with_nulls.json")

// Null is treated as "key absent" by both schemas.
#assert.eq(validate(raw), ())
#assert.eq(validate(raw, schema: resume-schema-strict), ())

#let faithful = parse(raw)
#let strict = parse(raw, schema: resume-schema-strict)

// Null fields are dropped, present scalars survive — both schemas
// behave identically on the null-as-absent contract.
#for model in (faithful, strict) {
  // Present scalars survive the coercion.
  assert.eq(model.basics.name, "Seán Ó Murchú")
  assert.eq(model.basics.email, "sean@example.com")
  assert.eq(model.work.at(0).name, "Acme Corp")
  assert.eq(model.work.at(0).startDate, "2022-01")

  // Null basics fields are absent from the coerced dict.
  assert("phone" not in model.basics)
  assert("url" not in model.basics)
  assert("summary" not in model.basics)
  assert("image" not in model.basics)
  assert("location" not in model.basics)
  assert("profiles" not in model.basics)

  // Null work-item fields are absent from the coerced dict.
  assert("endDate" not in model.work.at(0))
  assert("summary" not in model.work.at(0))
  assert("url" not in model.work.at(0))

  // Live array elements survive; null siblings are dropped.
  assert.eq(model.work.at(0).highlights.len(), 2)

  // Null entry inside an array of objects is dropped wholesale;
  // surviving siblings intact and indexable in order.
  assert.eq(model.work.len(), 2)
  assert.eq(model.work.at(1).name, "Globex")
  assert.eq(model.work.at(1).position, "Staff Engineer")
  assert.eq(model.work.at(1).startDate, "2018-06")
  assert.eq(model.work.at(1).endDate, "2021-12")

  // Whole-section nulls disappear from the top-level model.
  assert("skills" not in model)
  assert("languages" not in model)
  assert("interests" not in model)
  assert("references" not in model)
  assert("projects" not in model)
  assert("volunteer" not in model)
  assert("education" not in model)
  assert("awards" not in model)
  assert("certificates" not in model)
  assert("publications" not in model)
  assert("meta" not in model)
}

// Diverging behaviour: highlights coerce to str under faithful, to
// content under strict — the same survivor count + element kinds
// reflect the source-vs-renderer split.
#assert.eq(type(faithful.work.at(0).highlights.at(0)), str)
#assert.eq(type(faithful.work.at(0).highlights.at(1)), str)
#assert.eq(type(strict.work.at(0).highlights.at(0)), content)
#assert.eq(type(strict.work.at(0).highlights.at(1)), content)
