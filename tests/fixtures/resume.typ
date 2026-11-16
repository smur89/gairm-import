// The JSON Resume schema (https://jsonresume.org/schema, 1.7.0) as a
// large real-world fixture: translated from jsonresume-schema.json, and
// the stricter variant README.md's "Validating a JSON Resume" builds
// from it (tests/package/readme-json-resume.typ asserts the README's
// recipe builds these same two schemas).
// Not a test itself: the fixture tests import it.
#import "../../lib.typ": schema-from-json-schema, lens-put, content-type

#let resume-schema = schema-from-json-schema(json("jsonresume-schema.json"))

// Not for schemas with `not` or `if`: closing an object there loosens them.
#let _close(js) = if type(js) == dictionary {
  let js = js.pairs().map(((k, v)) => (k, _close(v))).to-dict()
  if (
    "properties" in js and js.at("additionalProperties", default: true) == true
  ) {
    js.additionalProperties = false
  }
  js
} else if type(js) == array { js.map(_close) } else { js }

#let _strict-json = {
  let js = _close(json("jsonresume-schema.json"))
  js.definitions.iso8601 = (type: "string", format: "date")
  js.properties.meta.properties.lastModified = (
    anyOf: (
      (type: "string", format: "date-time"),
      (type: "string", format: "date"),
    ),
  )
  js
}

// Free-text fields, as Typst content.
#let content-paths = (
  ("objective",),
  ("basics", "summary"),
  ("work", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("volunteer", "items", "highlights", "items"),
  ("education", "items", "summary"),
  ("awards", "items", "summary"),
  ("certificates", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("projects", "items", "summary"),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
)

#let resume-schema-strict = content-paths.fold(
  schema-from-json-schema(_strict-json),
  (schema, at) => lens-put(schema, at, content-type),
)
