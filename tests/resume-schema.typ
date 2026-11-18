// The JSON Resume schema (fixtures/jsonresume-schema.json, v1.7.0)
// as a large real-world translation: the translator handles every
// keyword the document uses, and types each field as upstream does.

#import "../lib.typ": (
  lens-get, schema-from-json-schema, validate, object, describe-schema, string,
)
#import "fixtures/resume.typ": resume-schema

// ---- the translated document ---------------------------------------------

// The canonical document translates through either entry form, and the
// result validates a full resume: the translator handles every keyword
// the document uses, not just synthetic fragments.
#assert.eq(
  schema-from-json-schema(path("fixtures/jsonresume-schema.json")),
  resume-schema,
)
#assert.eq(
  validate(resume-schema, json("fixtures/resume-full.json")),
  (),
)

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

// ---- the kind at a path ----------------------------------------------------
//
// Each row: a path and its node, the upstream document's own typing. A
// `str` is how describe-schema draws the node, for nodes compared by
// kind. Every upstream `format` field is here.

#let iso = "string + pattern" // an upstream `$ref` to iso8601's pattern
#for (path, want) in (
  // Free text is a plain string.
  (("objective",), string()),
  (("basics", "summary"), string()),
  (("work", "items", "highlights", "items"), string()),
  (("projects", "items", "description"), string()),
  // iso8601 fields carry upstream's pattern.
  (("work", "items", "startDate"), iso),
  (("education", "items", "endDate"), iso),
  (("certificates", "items", "expiryDate"), iso),
  (("publications", "items", "releaseDate"), iso),
  (("references", "items", "date"), iso),
  // meta.lastModified has no upstream pattern, only a description.
  (("meta", "lastModified"), string()),
  // Format fields carry their format.
  (("basics", "email"), string(format: "email")),
  (("basics", "url"), string(format: "uri")),
  (("work", "items", "url"), string(format: "uri")),
  (("volunteer", "items", "url"), string(format: "uri")),
  (("education", "items", "url"), string(format: "uri")),
  (("certificates", "items", "url"), string(format: "uri")),
  (("publications", "items", "url"), string(format: "uri")),
  (("projects", "items", "url"), string(format: "uri")),
  (("meta", "canonical"), string(format: "uri")),
  // basics.image is described as a URL but not annotated as one.
  (("basics", "image"), string()),
  (("skills", "items", "keywords"), (kind: "array", elem: string())),
  (("education", "items", "courses", "items"), string()),
) {
  let node = lens-get(resume-schema, path)
  if type(want) == str { node = describe-schema(node) }
  assert.eq(node, want, message: repr(path))
}

// Upstream leaves nested objects open; `custom` is a free-form bag.
#for path in (("work", "items"), ("languages", "items"), ("skills", "items")) {
  assert.eq(lens-get(resume-schema, path).additional, true)
}
