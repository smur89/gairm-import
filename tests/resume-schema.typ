// The bundled schemas. `resume-schema` is translated from the vendored
// canonical JSON Resume document (v1.7.0), faithful to it;
// `resume-schema-strict` adds the package's opinions: free-text fields
// as content, iso8601 fields as date-string, meta.lastModified as a
// datetime or date, and no undeclared keys.

#import "../internal/json-resume/schema.typ": _strip-permissive-additional
#import "../lib.typ": (
  lens-get, resume-schema, resume-schema-strict, schema-from-json-schema,
  validate, object, any-of, not-of, if-of, content-type, describe-schema,
  string, number,
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
#assert.eq(resume-schema.shape.at("$schema"), string(format: "uri"))
#assert.eq(resume-schema.shape.objective, string())
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
// own typing), and in resume-schema-strict. A `str` row is how
// describe-schema draws the node, for nodes compared by kind. Every
// path the strict overrides name is here, so a stale one fails rather
// than silently losing a date check; so is every upstream `format`
// field.

#let iso = "string + pattern" // an upstream `$ref` to iso8601's pattern
#for (path, faithful, strict) in (
  // Free-text fields: str upstream, content in strict.
  (("objective",), string(), content-type),
  (("basics", "summary"), string(), content-type),
  (("work", "items", "summary"), string(), content-type),
  (("work", "items", "highlights", "items"), string(), content-type),
  (("volunteer", "items", "summary"), string(), content-type),
  (("volunteer", "items", "highlights", "items"), string(), content-type),
  (("education", "items", "summary"), string(), content-type),
  (("awards", "items", "summary"), string(), content-type),
  (("certificates", "items", "summary"), string(), content-type),
  (("publications", "items", "summary"), string(), content-type),
  (("references", "items", "reference"), string(), content-type),
  (("projects", "items", "summary"), string(), content-type),
  (("projects", "items", "description"), string(), content-type),
  (("projects", "items", "highlights", "items"), string(), content-type),
  // iso8601 fields: the upstream pattern, string(format: "date") in strict.
  (("work", "items", "startDate"), iso, string(format: "date")),
  (("work", "items", "endDate"), iso, string(format: "date")),
  (("volunteer", "items", "startDate"), iso, string(format: "date")),
  (("volunteer", "items", "endDate"), iso, string(format: "date")),
  (("education", "items", "startDate"), iso, string(format: "date")),
  (("education", "items", "endDate"), iso, string(format: "date")),
  (("awards", "items", "date"), iso, string(format: "date")),
  (("certificates", "items", "date"), iso, string(format: "date")),
  (("certificates", "items", "expiryDate"), iso, string(format: "date")),
  (("publications", "items", "releaseDate"), iso, string(format: "date")),
  (("projects", "items", "startDate"), iso, string(format: "date")),
  (("projects", "items", "endDate"), iso, string(format: "date")),
  (("references", "items", "date"), iso, string(format: "date")),
  // meta.lastModified has no upstream pattern, only a description.
  (
    ("meta", "lastModified"),
    string(),
    any-of((string(format: "date-time"), string(format: "date"))),
  ),
  // Format fields carry their kind in both.
  (("basics", "email"), string(format: "email"), string(format: "email")),
  (("basics", "url"), string(format: "uri"), string(format: "uri")),
  (("work", "items", "url"), string(format: "uri"), string(format: "uri")),
  (("volunteer", "items", "url"), string(format: "uri"), string(format: "uri")),
  (("education", "items", "url"), string(format: "uri"), string(format: "uri")),
  (
    ("certificates", "items", "url"),
    string(format: "uri"),
    string(format: "uri"),
  ),
  (
    ("publications", "items", "url"),
    string(format: "uri"),
    string(format: "uri"),
  ),
  (("projects", "items", "url"), string(format: "uri"), string(format: "uri")),
  (("meta", "canonical"), string(format: "uri"), string(format: "uri")),
  // basics.image is described as a URL but not annotated as one.
  (("basics", "image"), string(), string()),
  // Identifiers and tag lists stay strings in both.
  (("basics", "name"), string(), string()),
  (
    ("skills", "items", "keywords"),
    (kind: "array", elem: string()),
    (
      kind: "array",
      elem: string(),
    ),
  ),
  (("education", "items", "courses", "items"), string(), string()),
) {
  for (schema, want) in (
    (resume-schema, faithful),
    (resume-schema-strict, strict),
  ) {
    let node = lens-get(schema, path)
    if type(want) == str { node = describe-schema(node) }
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
  object((x: string()), additional: true),
  string(),
)))
#assert("additional" not in stripped.members.at(0))
#assert.eq(stripped.members.at(1), string())
#assert.eq(
  _strip-permissive-additional(any-of((object((:), additional: number()),)))
    .members
    .at(0)
    .additional,
  number(),
)
// A `not` member stays as authored: closing a negated matcher would
// make it reject less.
#let negated = not-of(object((x: string()), additional: true))
#assert.eq(_strip-permissive-additional(negated), negated)
// So does a conditional's condition, which only picks the branch; the
// branches close.
#let open-x = object((x: string()), additional: true)
#assert.eq(
  _strip-permissive-additional(if-of(open-x, then: open-x, otherwise: open-x)),
  if-of(open-x, then: object((x: string())), otherwise: object((x: string()))),
)
