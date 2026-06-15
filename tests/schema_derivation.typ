// Regression pin: every path in internal/schema.typ's `_content-paths`
// must land at a content-type leaf in the derived resume-schema.
// Catches stale paths after an upstream schema bump (where a field is
// renamed or removed) and refactors that break the lens-fold.

#import "../lib.typ": resume-schema, content-type, str-type

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

// Spot-check neighbouring leaves to confirm we didn't accidentally
// over-coerce — non-renderable fields stay as plain str.
#assert.eq(resume-schema.shape.basics.shape.email, str-type)
#assert.eq(resume-schema.shape.work.elem.shape.startDate, str-type)
#assert.eq(resume-schema.shape.references.elem.shape.name, str-type)
#assert.eq(resume-schema.shape.projects.elem.shape.url, str-type)
