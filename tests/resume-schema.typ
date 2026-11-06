// The bundled schemas. `resume-schema` is translated from the vendored
// canonical JSON Resume document (v1.7.0), faithful to it;
// `resume-schema-strict` adds the package's opinions: free-text fields
// as content, iso8601 fields as date-string, meta.lastModified as a
// datetime or date, and no undeclared keys.

#import "../internal/json-resume/schema.typ": _strip-permissive-additional
#import "../lib.typ": (
  lens-get, resume-schema, resume-schema-strict, schema-from-json-schema,
  validate, object, any-of, not-of, str-type, content-type, number-type,
  date-string, datetime-string, uri-string, email-string,
)

// ---- the translated document ---------------------------------------------

// The canonical document translates through either entry form, and the
// result validates a full resume: the translator handles every keyword
// the document uses, not just synthetic fragments.
#let source = "../internal/json-resume/schema.json"
#let canonical = schema-from-json-schema(json(source))
#assert.eq(schema-from-json-schema(path(source)), canonical)
#assert.eq(canonical, resume-schema)
#assert.eq(validate(json("fixtures/resume-full.json"), schema: canonical), ())

#assert.eq(resume-schema.shape.keys().sorted(), (
  "$schema",
  "awards",
  "basics",
  "certificates",
  "custom",
  "education",
  "interests",
  "languages",
  "meta",
  "objective",
  "projects",
  "publications",
  "references",
  "skills",
  "volunteer",
  "work",
))

// Every section is an object (basics, meta) or an array of objects,
// with a non-empty shape. Derived from the schema, so a new section is
// covered without editing this file. `$schema` is a URI, `objective` a
// string, and `custom` a free-form bag.
#assert.eq(resume-schema.kind, "object")
#assert.eq(resume-schema.shape.at("$schema"), uri-string)
#assert.eq(resume-schema.shape.objective, str-type)
#assert.eq(resume-schema.shape.custom, object((:), additional: true))
#for (key, sub) in resume-schema.shape.pairs() {
  if key in ("$schema", "objective", "custom") { continue }
  let element = if sub.kind == "array" { sub.elem } else { sub }
  assert.eq(element.kind, "object", message: key)
  assert(element.shape.len() > 0, message: key + " has an empty shape")
}

// ---- each schema's kind at a path ------------------------------------------
//
// Each row: a path, its node in resume-schema (the upstream document's
// own typing), and in resume-schema-strict. A `str` row is a kind name,
// for nodes compared by kind. Every path the strict overrides name is
// here, so a stale one fails rather than silently losing a date check;
// so is every upstream `format` field.

#let iso = "pattern-string" // an upstream `$ref` to iso8601's pattern
#for (path, faithful, strict) in (
  // Free-text fields: str upstream, content in strict.
  (("objective",), str-type, content-type),
  (("basics", "summary"), str-type, content-type),
  (("work", "items", "summary"), str-type, content-type),
  (("work", "items", "highlights", "items"), str-type, content-type),
  (("volunteer", "items", "summary"), str-type, content-type),
  (("volunteer", "items", "highlights", "items"), str-type, content-type),
  (("education", "items", "summary"), str-type, content-type),
  (("awards", "items", "summary"), str-type, content-type),
  (("certificates", "items", "summary"), str-type, content-type),
  (("publications", "items", "summary"), str-type, content-type),
  (("references", "items", "reference"), str-type, content-type),
  (("projects", "items", "summary"), str-type, content-type),
  (("projects", "items", "description"), str-type, content-type),
  (("projects", "items", "highlights", "items"), str-type, content-type),
  // iso8601 fields: the upstream pattern, date-string in strict.
  (("work", "items", "startDate"), iso, date-string),
  (("work", "items", "endDate"), iso, date-string),
  (("volunteer", "items", "startDate"), iso, date-string),
  (("volunteer", "items", "endDate"), iso, date-string),
  (("education", "items", "startDate"), iso, date-string),
  (("education", "items", "endDate"), iso, date-string),
  (("awards", "items", "date"), iso, date-string),
  (("certificates", "items", "date"), iso, date-string),
  (("certificates", "items", "expiryDate"), iso, date-string),
  (("publications", "items", "releaseDate"), iso, date-string),
  (("projects", "items", "startDate"), iso, date-string),
  (("projects", "items", "endDate"), iso, date-string),
  (("references", "items", "date"), iso, date-string),
  // meta.lastModified has no upstream pattern, only a description.
  (("meta", "lastModified"), str-type, any-of((datetime-string, date-string))),
  // Format fields carry their kind in both.
  (("basics", "email"), email-string, email-string),
  (("basics", "url"), uri-string, uri-string),
  (("work", "items", "url"), uri-string, uri-string),
  (("volunteer", "items", "url"), uri-string, uri-string),
  (("education", "items", "url"), uri-string, uri-string),
  (("certificates", "items", "url"), uri-string, uri-string),
  (("publications", "items", "url"), uri-string, uri-string),
  (("projects", "items", "url"), uri-string, uri-string),
  (("meta", "canonical"), uri-string, uri-string),
  // basics.image is described as a URL but not annotated as one.
  (("basics", "image"), str-type, str-type),
  // Identifiers and tag lists stay strings in both.
  (("basics", "name"), str-type, str-type),
  (
    ("skills", "items", "keywords"),
    (kind: "array", elem: str-type),
    (
      kind: "array",
      elem: str-type,
    ),
  ),
  (("education", "items", "courses", "items"), str-type, str-type),
) {
  for (schema, want) in (
    (resume-schema, faithful),
    (resume-schema-strict, strict),
  ) {
    let node = lens-get(schema, path)
    if type(want) == str { node = node.kind }
    assert.eq(node, want, message: repr(path))
  }
}

// ---- strict closes every object --------------------------------------------
//
// resume-schema-strict strips the `additional: true` upstream puts on
// nested objects, restoring the rejection of unknown keys; the faithful
// base keeps them. `custom` declares no fields, so it is a free-form
// bag and stays open, at the top level and in every section.
#for path in (("work", "items"), ("languages", "items"), ("skills", "items")) {
  assert.eq(lens-get(resume-schema, path).additional, true)
  assert("additional" not in lens-get(resume-schema-strict, path))
}
#assert("additional" not in resume-schema-strict.shape.basics)
#assert.eq(resume-schema-strict.shape.custom.additional, true)
#assert.eq(resume-schema-strict.shape.work.elem.shape.custom.additional, true)

// The strip recurses into union members: a member is a positive matcher
// for the document, so closing it tightens. A typed `additional` is kept.
#let stripped = _strip-permissive-additional(any-of((
  object((x: str-type), additional: true),
  str-type,
)))
#assert("additional" not in stripped.members.at(0))
#assert.eq(stripped.members.at(1), str-type)
#assert.eq(
  _strip-permissive-additional(any-of((object((:), additional: number-type),)))
    .members
    .at(0)
    .additional,
  number-type,
)
// A `not` member stays as authored: closing a negated matcher would
// make it reject less.
#let negated = not-of(object((x: str-type), additional: true))
#assert.eq(_strip-permissive-additional(negated), negated)
