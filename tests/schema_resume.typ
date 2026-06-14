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
    assert.eq(
      sub-schema.kind, "str",
      message: "$schema must be str-typed; got " + sub-schema.kind,
    )
  } else {
    let kind = sub-schema.kind
    let ok = (
      kind == "object" or (kind == "array" and sub-schema.elem.kind == "object")
    )
    assert(
      ok,
      message: "resume-schema." + key + " must be object or array-of(object); got " + kind,
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

// Spot-checks on content-coerced fields the issue called out.
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
