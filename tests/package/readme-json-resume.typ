// Mirrors README.md, "Validating a JSON Resume": the plain translation,
// the types it says the result holds, and the stricter schema. The
// README reads the user's own `resume.schema.json`; here that is the
// vendored copy behind the deprecated exports, so each recipe must
// equal the export it replaces. resume.json (this directory) matches
// the README; the asserts are ours.
#import "@preview/gairm-import:0.0.0": (
  parse, schema-from-json-schema, lens-put, content-type,
)

#let schema-file = "/internal/json-resume/schema.json"

#let resume-schema = schema-from-json-schema(json(schema-file))
#let resume = parse(path("resume.json"), schema: resume-schema)
// hand `resume` to any compatible Typst CV template

#assert.eq(resume.basics.name, "Seán Ó Murchú")
#assert.eq(resume.basics.email, "sean@example.com")
#assert.eq(resume.work.len(), 1)
#assert.eq(resume.work.first().name, "Acme Corp")
#assert.eq(
  resume.work.first().highlights,
  ("Led the event-sourcing platform migration.",),
)

// Every field the README names is a plain str, or an array of them.
#for value in (
  resume.basics.name,
  resume.basics.summary,
  resume.basics.email,
  resume.work.first().position,
  ..resume.work.first().highlights,
) {
  assert.eq(type(value), str)
}

#let close(js) = if type(js) == dictionary {
  let js = js.pairs().map(((k, v)) => (k, close(v))).to-dict()
  if (
    "properties" in js and js.at("additionalProperties", default: true) == true
  ) {
    js.additionalProperties = false
  }
  js
} else if type(js) == array { js.map(close) } else { js }

#let strict-json = {
  let js = close(json(schema-file))
  js.definitions.iso8601 = (type: "string", format: "date")
  js.properties.meta.properties.lastModified = (
    anyOf: (
      (type: "string", format: "date-time"),
      (type: "string", format: "date"),
    ),
  )
  js
}

#let resume-schema-strict = (
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
).fold(
  schema-from-json-schema(strict-json),
  (schema, at) => lens-put(schema, at, content-type),
)

#let strict = parse(path("resume.json"), schema: resume-schema-strict)
#assert.eq(type(strict.basics.summary), content)
#assert.eq(type(strict.basics.email), str)

// The deprecated exports are these recipes, until 1.0 removes them.
#{
  import "@preview/gairm-import:0.0.0" as gairm
  assert.eq(resume-schema, gairm.resume-schema)
  assert.eq(resume-schema-strict, gairm.resume-schema-strict)
}
