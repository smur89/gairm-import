// Mirrors README.md, "Validating a JSON Resume": the plain translation
// and the types it says the result holds. The README reads the user's
// own `resume.schema.json`; here that is the test fixture's copy.
// resume.json (this directory) matches the README; the asserts are ours.
// Other doc mirrors import the schema from here; REFERENCE.md's stricter
// variant is in reference-json-resume.typ.
#import "@preview/gairm-import:0.0.0": parse, schema-from-json-schema

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

// The fixture tests run against the same schema.
#{
  import "/tests/fixtures/resume.typ" as fixture
  assert.eq(resume-schema, fixture.resume-schema)
}
