// End-to-end against a fixture exercising every JSON Resume section.
// Runs the full pipeline against BOTH exported schemas:
//
//  - `resume-schema` (faithful): free-text fields and iso8601 `$ref`
//    fields stay as plain str — the upstream document doesn't carry
//    `content` or `date-string` semantics, so neither does the model.
//  - `resume-schema-strict`: same input, but free-text fields become
//    content (Typst inline-renderable) and iso8601 `$ref` fields are
//    regex-gated as ISO-8601 dates.
//
// The fixture's `meta.lastModified` is encoded as a date-only string
// (`2026-06-15`) rather than the JSON-Resume-described
// `YYYY-MM-DDThh:mm:ss` datetime — the strict schema's date-string
// regex is date-only by design (see internal/validate.typ comment on
// _format-specs), so reverting to a datetime would break the strict
// validate() call below and the test would fail loudly. That's the
// signal: if the regex ever grows to accept datetimes, update both
// the fixture and this comment.

#import "../lib.typ": validate, parse, resume-schema-strict

#let raw = json("fixtures/resume_full.json")

// Both schemas validate cleanly against the same fixture.
#assert.eq(validate(raw), ())
#assert.eq(validate(raw, schema: resume-schema-strict), ())

#let faithful = parse(raw)
#let strict = parse(raw, schema: resume-schema-strict)

// Every section is present in both.
#for model in (faithful, strict) {
  assert("name" in model.basics)
  assert(model.work.len() >= 1)
  assert(model.volunteer.len() >= 1)
  assert(model.education.len() >= 1)
  assert(model.awards.len() >= 1)
  assert(model.certificates.len() >= 1)
  assert(model.publications.len() >= 1)
  assert(model.skills.len() >= 1)
  assert(model.languages.len() >= 1)
  assert(model.interests.len() >= 1)
  assert(model.references.len() >= 1)
  assert(model.projects.len() >= 1)
  assert("canonical" in model.meta)
}

// Free-text fields: plain str under the faithful schema, Typst content
// under the strict schema. Same source value, different output kind.
#assert.eq(type(faithful.basics.summary), str)
#assert.eq(type(strict.basics.summary), content)
#assert.eq(type(faithful.work.at(0).summary), str)
#assert.eq(type(strict.work.at(0).summary), content)
#assert.eq(type(faithful.work.at(0).highlights.at(0)), str)
#assert.eq(type(strict.work.at(0).highlights.at(0)), content)
#assert.eq(type(faithful.references.at(0).reference), str)
#assert.eq(type(strict.references.at(0).reference), content)
#assert.eq(type(faithful.projects.at(0).description), str)
#assert.eq(type(strict.projects.at(0).description), content)
#assert.eq(type(faithful.projects.at(0).highlights.at(0)), str)
#assert.eq(type(strict.projects.at(0).highlights.at(0)), content)
#assert.eq(type(faithful.awards.at(0).summary), str)
#assert.eq(type(strict.awards.at(0).summary), content)
#assert.eq(type(faithful.publications.at(0).summary), str)
#assert.eq(type(strict.publications.at(0).summary), content)
#assert.eq(type(faithful.volunteer.at(0).highlights.at(0)), str)
#assert.eq(type(strict.volunteer.at(0).highlights.at(0)), content)

// Tag-like arrays stay as strings under both schemas — no override
// targets them.
#for model in (faithful, strict) {
  assert.eq(type(model.skills.at(0).keywords.at(0)), str)
  assert.eq(type(model.education.at(0).courses.at(0)), str)
  assert.eq(type(model.projects.at(0).keywords.at(0)), str)
  assert.eq(type(model.projects.at(0).roles.at(0)), str)
  assert.eq(type(model.interests.at(0).keywords.at(0)), str)
}

// Plain-string identifiers stay as strings under both schemas. The
// date fields are gated against the date-string regex under strict
// but the coerced value is still a plain string.
#for model in (faithful, strict) {
  assert.eq(type(model.basics.email), str)
  assert.eq(type(model.work.at(0).url), str)
  assert.eq(type(model.work.at(0).startDate), str)
  assert.eq(type(model.meta.version), str)
  assert.eq(type(model.meta.lastModified), str)
}

// Pin the fixture's lastModified encoding so the workaround is
// visible. If this assertion ever fails, either the fixture has been
// reverted to a datetime (revert that), or the date-string regex
// grew to accept datetimes (in which case update both this assertion
// and the file-header comment above).
#assert.eq(faithful.meta.lastModified, "2026-06-15")
