// Regression pin for `resume-schema-strict`: every path in
// internal/schema.typ's `_content-paths` and `_date-paths` lands at
// the expected kind. Catches stale paths after an upstream schema
// bump (renamed/removed field) and refactors that break the
// lens-fold.

#import "../lib.typ": (
  resume-schema, resume-schema-strict,
  str-type, content-type, date-string, uri-string, email-string,
)

// _content-paths: free-text fields wrapped to content-type.
#assert.eq(resume-schema-strict.shape.basics.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.work.elem.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.work.elem.shape.highlights.elem, content-type)
#assert.eq(resume-schema-strict.shape.volunteer.elem.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.volunteer.elem.shape.highlights.elem, content-type)
#assert.eq(resume-schema-strict.shape.awards.elem.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.publications.elem.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.references.elem.shape.reference, content-type)
#assert.eq(resume-schema-strict.shape.projects.elem.shape.description, content-type)
#assert.eq(resume-schema-strict.shape.projects.elem.shape.highlights.elem, content-type)

// _date-paths: iso8601 $ref fields lifted to date-string.
#assert.eq(resume-schema-strict.shape.work.elem.shape.startDate, date-string)
#assert.eq(resume-schema-strict.shape.work.elem.shape.endDate, date-string)
#assert.eq(resume-schema-strict.shape.awards.elem.shape.date, date-string)
#assert.eq(resume-schema-strict.shape.publications.elem.shape.releaseDate, date-string)
#assert.eq(resume-schema-strict.shape.meta.shape.lastModified, date-string)

// Translator-emitted format kinds carry over from the faithful base.
#assert.eq(resume-schema-strict.shape.basics.shape.email, email-string)
#assert.eq(resume-schema-strict.shape.basics.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.certificates.elem.shape.date, date-string)

// Faithfulness: the strict overlay must NOT mutate the default
// resume-schema — the same paths come through as plain str there.
#assert.eq(resume-schema.shape.basics.shape.summary, str-type)
#assert.eq(resume-schema.shape.work.elem.shape.startDate, str-type)
#assert.eq(resume-schema.shape.references.elem.shape.reference, str-type)
