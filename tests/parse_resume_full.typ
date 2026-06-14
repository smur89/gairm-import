// End-to-end: a fixture exercising every JSON Resume section validates
// cleanly and coerces into the expected shape.

#import "../lib.typ": read-resume, validate-resume, parse-resume

#let raw = read-resume("/tests/fixtures/resume_full.json")

#assert.eq(validate-resume(raw), ())

#let model = parse-resume(raw)

// Every section is present.
#assert("name" in model.basics)
#assert(model.work.len() >= 1)
#assert(model.volunteer.len() >= 1)
#assert(model.education.len() >= 1)
#assert(model.awards.len() >= 1)
#assert(model.certificates.len() >= 1)
#assert(model.publications.len() >= 1)
#assert(model.skills.len() >= 1)
#assert(model.languages.len() >= 1)
#assert(model.interests.len() >= 1)
#assert(model.references.len() >= 1)
#assert(model.projects.len() >= 1)
#assert("canonical" in model.meta)

// Free-text fields are coerced to content.
#assert.eq(type(model.basics.summary), content)
#assert.eq(type(model.work.at(0).summary), content)
#assert.eq(type(model.work.at(0).highlights.at(0)), content)
#assert.eq(type(model.references.at(0).reference), content)
#assert.eq(type(model.projects.at(0).description), content)
#assert.eq(type(model.projects.at(0).highlights.at(0)), content)
#assert.eq(type(model.awards.at(0).summary), content)
#assert.eq(type(model.publications.at(0).summary), content)
#assert.eq(type(model.volunteer.at(0).highlights.at(0)), content)

// Tag-like arrays stay as strings.
#assert.eq(type(model.skills.at(0).keywords.at(0)), str)
#assert.eq(type(model.education.at(0).courses.at(0)), str)
#assert.eq(type(model.projects.at(0).keywords.at(0)), str)
#assert.eq(type(model.projects.at(0).roles.at(0)), str)
#assert.eq(type(model.interests.at(0).keywords.at(0)), str)

// Plain identifiers stay as strings.
#assert.eq(type(model.basics.email), str)
#assert.eq(type(model.work.at(0).url), str)
#assert.eq(type(model.work.at(0).startDate), str)
#assert.eq(type(model.meta.version), str)
