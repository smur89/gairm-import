// Regression pin: every path in internal/schema.typ's `_content-paths`
// and `_date-paths` must land at the expected kind in the derived
// resume-schema. Catches stale paths after an upstream schema bump
// (renamed/removed field) and refactors that break the lens-fold.

#import "../lib.typ": (
  resume-schema, str-type, content-type, date-string, uri-string, email-string,
)

// _content-paths: free-text fields wrapped to content-type.
#assert.eq(resume-schema.shape.basics.shape.summary, content-type)
#assert.eq(resume-schema.shape.work.elem.shape.summary, content-type)
#assert.eq(resume-schema.shape.work.elem.shape.highlights.elem, content-type)
#assert.eq(resume-schema.shape.volunteer.elem.shape.summary, content-type)
#assert.eq(resume-schema.shape.volunteer.elem.shape.highlights.elem, content-type)
#assert.eq(resume-schema.shape.awards.elem.shape.summary, content-type)
#assert.eq(resume-schema.shape.publications.elem.shape.summary, content-type)
#assert.eq(resume-schema.shape.references.elem.shape.reference, content-type)
#assert.eq(resume-schema.shape.projects.elem.shape.description, content-type)
#assert.eq(resume-schema.shape.projects.elem.shape.highlights.elem, content-type)

// _date-paths: iso8601 $ref fields lifted to date-string.
#assert.eq(resume-schema.shape.work.elem.shape.startDate, date-string)
#assert.eq(resume-schema.shape.work.elem.shape.endDate, date-string)
#assert.eq(resume-schema.shape.awards.elem.shape.date, date-string)
#assert.eq(resume-schema.shape.publications.elem.shape.releaseDate, date-string)
#assert.eq(resume-schema.shape.meta.shape.lastModified, date-string)

// Translator-emitted format kinds (no lens-override needed — the
// upstream JSON document carries the format keyword).
#assert.eq(resume-schema.shape.basics.shape.email, email-string)
#assert.eq(resume-schema.shape.basics.shape.url, uri-string)
#assert.eq(resume-schema.shape.certificates.elem.shape.date, date-string)

// Spot-check neighbouring leaves stay as plain str (no over-coercion).
#assert.eq(resume-schema.shape.basics.shape.name, str-type)
#assert.eq(resume-schema.shape.references.elem.shape.name, str-type)
#assert.eq(resume-schema.shape.skills.elem.shape.name, str-type)
