// Regression pin for `resume-schema-strict`: every path in
// internal/schema.typ's `_content-paths`, `_iso8601-date-paths`, and
// `_plain-date-paths` lands at the expected kind. Catches stale paths
// after an upstream schema bump (renamed/removed field) and refactors
// that break the lens-fold.

#import "../lib.typ": (
  resume-schema, resume-schema-strict, str-type, content-type, date-string,
  uri-string, email-string,
)

// _content-paths: free-text fields wrapped to content-type.
#assert.eq(resume-schema-strict.shape.basics.shape.summary, content-type)
#assert.eq(resume-schema-strict.shape.work.elem.shape.summary, content-type)
#assert.eq(
  resume-schema-strict.shape.work.elem.shape.highlights.elem,
  content-type,
)
#assert.eq(
  resume-schema-strict.shape.volunteer.elem.shape.summary,
  content-type,
)
#assert.eq(
  resume-schema-strict.shape.volunteer.elem.shape.highlights.elem,
  content-type,
)
#assert.eq(resume-schema-strict.shape.awards.elem.shape.summary, content-type)
#assert.eq(
  resume-schema-strict.shape.publications.elem.shape.summary,
  content-type,
)
#assert.eq(
  resume-schema-strict.shape.references.elem.shape.reference,
  content-type,
)
#assert.eq(
  resume-schema-strict.shape.projects.elem.shape.description,
  content-type,
)
#assert.eq(
  resume-schema-strict.shape.projects.elem.shape.highlights.elem,
  content-type,
)

// _iso8601-date-paths (+ _plain-date-paths for meta.lastModified):
// date fields lifted to date-string. Every path in those lists is
// pinned here so a stale or missing override surfaces as a test
// failure, not as silent loss of date validation.
#assert.eq(resume-schema-strict.shape.work.elem.shape.startDate, date-string)
#assert.eq(resume-schema-strict.shape.work.elem.shape.endDate, date-string)
#assert.eq(
  resume-schema-strict.shape.volunteer.elem.shape.startDate,
  date-string,
)
#assert.eq(resume-schema-strict.shape.volunteer.elem.shape.endDate, date-string)
#assert.eq(
  resume-schema-strict.shape.education.elem.shape.startDate,
  date-string,
)
#assert.eq(resume-schema-strict.shape.education.elem.shape.endDate, date-string)
#assert.eq(resume-schema-strict.shape.awards.elem.shape.date, date-string)
#assert.eq(
  resume-schema-strict.shape.publications.elem.shape.releaseDate,
  date-string,
)
#assert.eq(
  resume-schema-strict.shape.projects.elem.shape.startDate,
  date-string,
)
#assert.eq(resume-schema-strict.shape.projects.elem.shape.endDate, date-string)
#assert.eq(resume-schema-strict.shape.meta.shape.lastModified, date-string)

// Translator-emitted format kinds carry over from the faithful base.
// Pinning every upstream-format-annotated path so a future schema
// bump that drops a `format: "uri"` annotation surfaces here rather
// than as silent loss of URI validation.
#assert.eq(resume-schema-strict.shape.basics.shape.email, email-string)
#assert.eq(resume-schema-strict.shape.basics.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.work.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.volunteer.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.education.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.certificates.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.publications.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.projects.elem.shape.url, uri-string)
#assert.eq(resume-schema-strict.shape.meta.shape.canonical, uri-string)
#assert.eq(resume-schema-strict.shape.certificates.elem.shape.date, date-string)

// Faithfulness: the strict overlay must NOT mutate the default
// resume-schema. Free-text fields stay as plain str in the faithful
// base; iso8601 $ref fields land as pattern-string there (gated by the
// upstream regex) — only the strict overlay tightens them to
// date-string.
#assert.eq(resume-schema.shape.basics.shape.summary, str-type)
#assert.eq(resume-schema.shape.work.elem.shape.startDate.kind, "pattern-string")
#assert.eq(resume-schema.shape.references.elem.shape.reference, str-type)

// Strict variant strips `additional: true` from every nested object
// that inherited it from upstream JSON Resume — restoring the
// strict-rejection promise. Sample a few sections; the recursive
// walker covers every kind == "object" node.
#assert("additional" not in resume-schema-strict.shape.work.elem)
#assert("additional" not in resume-schema-strict.shape.languages.elem)
#assert("additional" not in resume-schema-strict.shape.skills.elem)
#assert("additional" not in resume-schema-strict.shape.basics)
// And the faithful base still carries them — that's the trade-off
// the strict variant exists to fix.
#assert.eq(resume-schema.shape.languages.elem.additional, true)
#assert.eq(resume-schema.shape.work.elem.additional, true)
