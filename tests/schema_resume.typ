// The canonical JSON Resume schema is declared as a data structure
// the validator/coercer engines walk. Spot-check the assembly.

#import "../internal/schema.typ": resume-schema

#assert.eq(resume-schema.kind, "object")

#let expected = (
  "$schema",
  "basics", "work", "volunteer", "education", "awards",
  "certificates", "publications", "skills", "languages",
  "interests", "references", "projects", "meta",
).sorted()
#assert.eq(resume-schema.shape.keys().sorted(), expected)

// Section-level shapes.
#assert.eq(resume-schema.shape.basics.kind, "object")
#assert.eq(resume-schema.shape.work.kind, "array")
#assert.eq(resume-schema.shape.work.elem.kind, "object")
#assert.eq(resume-schema.shape.meta.kind, "object")

// Content-typed fields per the issue's intent.
#assert.eq(resume-schema.shape.basics.shape.summary.kind, "content")
#assert.eq(resume-schema.shape.work.elem.shape.summary.kind, "content")
#assert.eq(resume-schema.shape.work.elem.shape.highlights.elem.kind, "content")
#assert.eq(resume-schema.shape.projects.elem.shape.description.kind, "content")
#assert.eq(resume-schema.shape.references.elem.shape.reference.kind, "content")

// Plain-string identifiers stay str-typed.
#assert.eq(resume-schema.shape.basics.shape.name.kind, "str")
#assert.eq(resume-schema.shape.basics.shape.email.kind, "str")
#assert.eq(resume-schema.shape.work.elem.shape.url.kind, "str")
#assert.eq(resume-schema.shape.work.elem.shape.startDate.kind, "str")

// Array-of-string fields (tags / lists).
#assert.eq(resume-schema.shape.skills.elem.shape.keywords.kind, "array")
#assert.eq(resume-schema.shape.skills.elem.shape.keywords.elem.kind, "str")
#assert.eq(resume-schema.shape.education.elem.shape.courses.elem.kind, "str")
