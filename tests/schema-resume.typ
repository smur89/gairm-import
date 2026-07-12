// The canonical JSON Resume schema is declared as a data structure
// the validator/coercer engines walk. Two flavours of check:
//
//  - Property checks derived FROM the schema itself, so adding a
//    section automatically extends coverage without test edits.
//  - Spot-checks pinning specific fields that callers and the README
//    depend on (free-text vs identifier vs tag-array).

#import "../internal/schema.typ": resume-schema

#assert.eq(resume-schema.kind, "object")

// Property: every top-level entry except the `$schema` metadata link
// is either an object (singleton section like `basics`/`meta`) or an
// array of objects (every other section). If a future section is
// added that violates this shape, this assertion surfaces it.
#for (key, sub-schema) in resume-schema.shape.pairs() {
  if key == "$schema" {
    // $schema is a URI in JSON Schema (carries the format: "uri" hint).
    assert.eq(
      sub-schema.kind,
      "uri-string",
      message: "$schema must be uri-string; got " + sub-schema.kind,
    )
  } else {
    let kind = sub-schema.kind
    let ok = (
      kind == "object" or (kind == "array" and sub-schema.elem.kind == "object")
    )
    assert(
      ok,
      message: "resume-schema."
        + key
        + " must be object or array-of(object); got "
        + kind,
    )
  }
}

// Property: every section is reachable from resume-schema.shape and
// every element schema (whether the section is an object or an
// array-of-object) has a non-empty shape. If a refactor accidentally
// drops the shape of a section, this fails.
#for (key, sub-schema) in resume-schema.shape.pairs() {
  if key == "$schema" { continue }
  let element-shape = if sub-schema.kind == "object" {
    sub-schema.shape
  } else {
    sub-schema.elem.shape
  }
  assert(
    element-shape.keys().len() > 0,
    message: "resume-schema." + key + " has empty element shape",
  )
}

// Spot-checks pinning the package's faithful-to-source policy: fields
// the upstream JSON Schema types as plain `string` come through as
// `str`, not as content or date kinds. Callers wanting renderer
// ergonomics or stricter date validation reach for
// `resume-schema-strict` (see tests/schema-strict.typ).
#assert.eq(resume-schema.shape.basics.shape.summary.kind, "str")
#assert.eq(resume-schema.shape.work.elem.shape.summary.kind, "str")
#assert.eq(resume-schema.shape.work.elem.shape.highlights.elem.kind, "str")
#assert.eq(resume-schema.shape.projects.elem.shape.description.kind, "str")
#assert.eq(resume-schema.shape.references.elem.shape.reference.kind, "str")

// Plain-string identifiers stay str-typed.
#assert.eq(resume-schema.shape.basics.shape.name.kind, "str")

// Format-specialised string fields carry their format kind. Coercion
// is still pass-through (see coerce-primitives.typ); _validate adds a
// regex gate for these kinds.
// Format-specialised kinds come from upstream `format` keywords. The
// canonical document annotates email + uri fields and one date field
// (certificates.date); other date fields use a `$ref` to iso8601 whose
// definition carries a `pattern`, so the translator now lands them as
// `pattern-string` (gated by the upstream regex) — the strict variant
// tightens that to date-string.
#assert.eq(resume-schema.shape.basics.shape.email.kind, "email-string")
#assert.eq(resume-schema.shape.basics.shape.url.kind, "uri-string")
// basics.image is described as a URL in prose but not annotated with
// `format: "uri"` upstream. Honour the source.
#assert.eq(resume-schema.shape.basics.shape.image.kind, "str")
#assert.eq(resume-schema.shape.work.elem.shape.url.kind, "uri-string")
#assert.eq(resume-schema.shape.work.elem.shape.startDate.kind, "pattern-string")
#assert.eq(resume-schema.shape.work.elem.shape.endDate.kind, "pattern-string")
#assert.eq(resume-schema.shape.awards.elem.shape.date.kind, "pattern-string")
#assert.eq(resume-schema.shape.certificates.elem.shape.date.kind, "date-string")
#assert.eq(
  resume-schema.shape.publications.elem.shape.releaseDate.kind,
  "pattern-string",
)
#assert.eq(resume-schema.shape.meta.shape.canonical.kind, "uri-string")
// `meta.lastModified` has no upstream pattern (only a description), so
// it stays as plain str — the strict variant lifts it to date-string.
#assert.eq(resume-schema.shape.meta.shape.lastModified.kind, "str")

// Array-of-string fields (tags / lists).
#assert.eq(resume-schema.shape.skills.elem.shape.keywords.kind, "array")
#assert.eq(resume-schema.shape.skills.elem.shape.keywords.elem.kind, "str")
#assert.eq(resume-schema.shape.education.elem.shape.courses.elem.kind, "str")
