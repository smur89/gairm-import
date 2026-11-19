// Mirrors README.md, "Validating a JSON Resume": the plain translation,
// the types it says the result holds, and the stricter schema. The
// README reads the user's own `resume.schema.json`; here that is the
// test fixture's copy. resume.json (this directory) matches the README;
// the asserts are ours. Other doc mirrors import the two schemas from
// here.
#import "@preview/gairm-import:0.0.0": (
  parse, schema-from-json-schema, lens-put, content-type,
)

#let schema-file = "/tests/fixtures/jsonresume-schema.json"

#let resume-schema = schema-from-json-schema(json(schema-file))
#let resume = parse(resume-schema, path("resume.json"))
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

// Not for schemas with `not` or `if`: closing an object there loosens them.
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
  // A full date, or the year and month JSON Resume also allows.
  js.definitions.iso8601 = (
    anyOf: (
      (type: "string", format: "date"),
      (type: "string", pattern: "^[0-9]{4}(-(0[1-9]|1[0-2]))?$"),
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

#let resume = parse(resume-schema-strict, path("resume.json"))

// The fixture tests run against the same two schemas.
#{
  import "/tests/fixtures/resume.typ" as fixture
  assert.eq(resume-schema, fixture.resume-schema)
  assert.eq(resume-schema-strict, fixture.resume-schema-strict)
}

// The strict schema reports a misspelt work key with a suggestion; the
// upstream one lets it through.
#{
  import "@preview/gairm-import:0.0.0": validate, format-errors
  let doc = (work: ((name: "Acme", positon: "Engineer"),))
  assert(
    format-errors(validate(resume-schema-strict, doc)).contains(
      "  - work[0].positon: unknown key \"positon\". Did you mean \"position\"?",
    ),
  )
  assert.eq(validate(resume-schema, doc), ())
}
